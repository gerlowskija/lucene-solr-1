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

package org.apache.solr.core.backup;

import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.solr.core.backup.repository.BackupRepository;

import static org.apache.solr.core.backup.BackupId.TRADITIONAL_BACKUP;
import static org.apache.solr.core.backup.BackupManager.ZK_STATE_DIR;

/**
 * Utility class for getting paths related to backups, or parsing information out of those paths.
 */
public class BackupFilePaths {

    private static final Pattern BACKUP_PROPS_ID_PTN = Pattern.compile("backup_([0-9]+).properties");
    private BackupRepository repository;
    private URI backupLoc;

    public BackupFilePaths(BackupRepository repository, URI backupLoc) {
        this.repository = repository;
        this.backupLoc = backupLoc;
    }

    /**
     * Return a URI for the 'index' location, responsible for holding index files for all backups at this location.
     *
     * Only valid for incremental backups.
     */
    public URI getIndexDir() {
        return repository.resolve(backupLoc, "index");
    }

    /**
     * Return a URI for the 'shard_backup_ids' location, which contains metadata files about each shard backup.
     *
     * Only valid for incremental backups.
     */
    public URI getShardBackupMetadataDir() {
        return repository.resolve(backupLoc, "shard_backup_ids");
    }

    public URI getBackupLocation() {
        return backupLoc;
    }

    /**
     * Create all locations required to store an incremental backup.
     *
     * @throws IOException for issues encountered using repository to create directories
     */
    public void createIncrementalBackupFolders() throws IOException {
        if (!repository.exists(backupLoc)) {
            repository.createDirectory(backupLoc);
        }
        URI indexDir = getIndexDir();
        if (!repository.exists(indexDir)) {
            repository.createDirectory(indexDir);
        }

        URI shardBackupMetadataDir = getShardBackupMetadataDir();
        if (!repository.exists(shardBackupMetadataDir)) {
            repository.createDirectory(shardBackupMetadataDir);
        }
    }

    /**
     * Get the directory name used to hold backed up ZK state
     *
     * Valid for both incremental and traditional backups.
     *
     * @param id the ID of the backup in question
     */
    public static String getZkStateDir(BackupId id) {
        if (id.id == TRADITIONAL_BACKUP) {
            return ZK_STATE_DIR;
        }
        return String.format(Locale.ROOT, "%s_%d/", ZK_STATE_DIR, id.id);
    }

    /**
     * Get the filename of the top-level backup properties file
     *
     * Valid for both incremental and traditional backups.
     *
     * @param id the ID of the backup in question
     */
    public static String getBackupPropsName(BackupId id) {
        if (id.id == TRADITIONAL_BACKUP) {
            return BackupManager.BACKUP_PROPS_FILE;
        }
        return getBackupPropsName(id.id);
    }

    /**
     * Identify all strings which appear to be the filename of a top-level backup properties file.
     *
     * Only valid for incremental backups.
     *
     * @param listFiles a list of strings, filenames which may or may not correspond to backup properties files
     */
    public static List<BackupId> findAllBackupIdsFromFileListing(String[] listFiles) {
        List<BackupId> result = new ArrayList<>();
        for (String file: listFiles) {
            Matcher m = BACKUP_PROPS_ID_PTN.matcher(file);
            if (m.find()) {
                result.add(new BackupId(Integer.parseInt(m.group(1))));
            }
        }

        return result;
    }

    /**
     * Identify the string from an array of filenames which represents the most recent top-level backup properties file.
     *
     * Only valid for incremental backups.
     *
     * @param listFiles a list of strings, filenames which may or may not correspond to backup properties files.
     */
    public static Optional<BackupId> findMostRecentBackupIdFromFileListing(String[] listFiles) {
        return findAllBackupIdsFromFileListing(listFiles).stream().max(Comparator.comparingInt(o -> o.id));
    }

    private static String getBackupPropsName(int id) {
        return String.format(Locale.ROOT, "backup_%d.properties", id);
    }
}
