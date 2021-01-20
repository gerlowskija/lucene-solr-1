/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.solr.handler;

import java.io.IOException;
import java.lang.invoke.MethodHandles;
import java.net.URI;
import java.time.Instant;
import java.util.Collection;
import java.util.Optional;
import java.util.UUID;

import org.apache.commons.math3.util.Precision;
import org.apache.lucene.index.IndexCommit;
import org.apache.lucene.store.Directory;
import org.apache.solr.cloud.CloudDescriptor;
import org.apache.solr.common.SolrException;
import org.apache.solr.common.util.NamedList;
import org.apache.solr.core.DirectoryFactory;
import org.apache.solr.core.IndexDeletionPolicyWrapper;
import org.apache.solr.core.SolrCore;
import org.apache.solr.core.backup.Checksum;
import org.apache.solr.core.backup.ShardBackupId;
import org.apache.solr.core.backup.repository.BackupRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Backup a core in an incremental way by leveraging information from previous backups ({@link ShardBackupId}
 */
public class IncrementalShardBackup {
    private static final Logger log = LoggerFactory.getLogger(MethodHandles.lookup().lookupClass());
    private SolrCore solrCore;

    private BackupFilePaths incBackupFiles;
    private BackupRepository backupRepo;

    private String prevShardBackupIdFile;
    private String shardBackupIdFile;

    /**
     *
     * @param prevShardBackupIdFile previous ShardBackupId file which will be used for skipping
     *                             uploading index files already present in this file.
     * @param shardBackupIdFile file where all meta data of this backup will be stored to.
     */
    public IncrementalShardBackup(BackupRepository backupRepo, SolrCore solrCore, BackupFilePaths incBackupFiles,
                                  String prevShardBackupIdFile, String shardBackupIdFile) {
        this.backupRepo = backupRepo;
        this.solrCore = solrCore;
        this.incBackupFiles = incBackupFiles;
        this.prevShardBackupIdFile = prevShardBackupIdFile;
        this.shardBackupIdFile = shardBackupIdFile;
    }

    @SuppressWarnings({"rawtypes"})
    public NamedList backup() throws Exception {
        final IndexCommit indexCommit = getAndSaveIndexCommit();
        try {
            return backup(indexCommit);
        } finally {
            solrCore.getDeletionPolicy().releaseCommitPoint(indexCommit.getGeneration());
        }
    }

    /**
     * Returns {@link IndexDeletionPolicyWrapper#getAndSaveLatestCommit}.
     * <p>
     * Note:
     * <ul>
     *  <li>This method does error handling when the commit can't be found and wraps them in {@link SolrException}
     *  </li>
     *  <li>If this method returns, the result will be non null, and the caller <em>MUST</em>
     *      call {@link IndexDeletionPolicyWrapper#releaseCommitPoint} when finished
     *  </li>
     * </ul>
     */
    private IndexCommit getAndSaveIndexCommit() throws IOException {
        final IndexDeletionPolicyWrapper delPolicy = solrCore.getDeletionPolicy();
        final IndexCommit commit = delPolicy.getAndSaveLatestCommit();
        if (null == commit) {
            throw new SolrException(SolrException.ErrorCode.BAD_REQUEST, "Index does not yet have any commits for core " +
                    solrCore.getName());
        }
        if (log.isDebugEnabled())   {
            log.debug("Using latest commit: generation={}", commit.getGeneration());
        }
        return commit;
    }

    // note: remember to reserve the indexCommit first so it won't get deleted concurrently
    @SuppressWarnings({"rawtypes"})
    protected NamedList backup(final IndexCommit indexCommit) throws Exception {
        assert indexCommit != null;
        URI backupLocation = incBackupFiles.getBackupLocation();
        log.info("Creating backup snapshot at {} shardBackupIdFile:{}", backupLocation, shardBackupIdFile);
        NamedList<Object> details = new NamedList<>();
        details.add("startTime", Instant.now().toString());

        Collection<String> files = indexCommit.getFileNames();
        Directory dir = solrCore.getDirectoryFactory().get(solrCore.getIndexDir(),
                DirectoryFactory.DirContext.DEFAULT, solrCore.getSolrConfig().indexConfig.lockType);
        try {
            BackupStats stats = incrementalCopy(files, dir);
            details.add("indexFileCount", stats.fileCount);
            details.add("uploadedIndexFileCount", stats.uploadedFileCount);
            details.add("indexSizeMB", stats.getIndexSizeMB());
            details.add("uploadedIndexFileMB", stats.getTotalUploadedMB());
        } finally {
            solrCore.getDirectoryFactory().release(dir);
        }

        CloudDescriptor cd = solrCore.getCoreDescriptor().getCloudDescriptor();
        if (cd != null) {
            details.add("shard", cd.getShardId());
        }

        details.add("endTime", Instant.now().toString());
        details.add("shardBackupId", shardBackupIdFile);
        log.info("Done creating backup snapshot at {} shardBackupIdFile:{}", backupLocation, shardBackupIdFile);
        return details;
    }

    private ShardBackupId getPrevBackupPoint() throws IOException {
        if (prevShardBackupIdFile == null) {
            return ShardBackupId.empty();
        }
        return ShardBackupId.from(backupRepo, incBackupFiles.getShardBackupIdDir(), prevShardBackupIdFile);
    }

    private BackupStats incrementalCopy(Collection<String> indexFiles, Directory dir) throws IOException {
        ShardBackupId oldBackupPoint = getPrevBackupPoint();
        ShardBackupId currentBackupPoint = ShardBackupId.empty();
        URI indexDir = incBackupFiles.getIndexDir();
        BackupStats backupStats = new BackupStats();

        for(String fileName : indexFiles) {
            Optional<ShardBackupId.BackedFile> opBackedFile = oldBackupPoint.getFile(fileName);
            Checksum originalFileCS = backupRepo.checksum(dir, fileName);

            if (opBackedFile.isPresent()) {
                ShardBackupId.BackedFile backedFile = opBackedFile.get();
                Checksum existedFileCS = backedFile.fileChecksum;
                if (existedFileCS.equals(originalFileCS)) {
                    currentBackupPoint.addBackedFile(opBackedFile.get());
                    backupStats.skippedUploadingFile(existedFileCS);
                    continue;
                }
            }

            String backedFileName = UUID.randomUUID().toString();
            backupRepo.copyIndexFileFrom(dir, fileName, indexDir, backedFileName);

            currentBackupPoint.addBackedFile(backedFileName, fileName, originalFileCS);
            backupStats.uploadedFile(originalFileCS);
        }

        currentBackupPoint.store(backupRepo, incBackupFiles.getShardBackupIdDir(), shardBackupIdFile);
        return backupStats;
    }

    private static class BackupStats {
        private int fileCount;
        private int uploadedFileCount;
        private long indexSize;
        private long totalUploadedBytes;

        public void uploadedFile(Checksum file) {
            fileCount++;
            uploadedFileCount++;
            indexSize += file.size;
            totalUploadedBytes += file.size;
        }

        public void skippedUploadingFile(Checksum existedFile) {
            fileCount++;
            indexSize += existedFile.size;
        }

        public double getIndexSizeMB() {
            return Precision.round(indexSize / (1024.0 * 1024), 3);
        }

        public double getTotalUploadedMB() {
            return Precision.round(totalUploadedBytes / (1024.0 * 1024), 3);
        }
    }
}
