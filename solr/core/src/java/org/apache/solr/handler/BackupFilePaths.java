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
import java.net.URI;
import java.util.Locale;

import org.apache.solr.core.backup.BackupId;
import org.apache.solr.core.backup.BackupManager;
import org.apache.solr.core.backup.repository.BackupRepository;

import static org.apache.solr.core.backup.BackupManager.ZK_STATE_DIR;

/**
 * Utility class for getting paths related to backups
 */
public class BackupFilePaths {

    private BackupRepository repository;
    private URI backupLoc;

    public BackupFilePaths(BackupRepository repository, URI backupLoc) {
        this.repository = repository;
        this.backupLoc = backupLoc;
    }

    /**
     * Get the directory name used to hold backed up ZK state
     *
     * Valid for both incremental and traditional backups.
     *
     * @param id the ID of the backup in question
     */
    public static String getZkStateDir(BackupId id) {
        if (id.id == -1) {
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
        if (id.id == -1) {
            return BackupManager.BACKUP_PROPS_FILE;
        }
        return getBackupPropsName(id.id);
    }

    private static String getBackupPropsName(int id) {
        return String.format(Locale.ROOT, "backup_%d.properties", id);
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
    public URI getShardBackupIdDir() {
        return repository.resolve(backupLoc, "shard_backup_ids");
    }

    public URI getBackupLocation() {
        return backupLoc;
    }

    /**
     * Create all locations required to store an incremental backup.
     *
     * @throws IOException
     */
    public void createIncrementalBackupFolders() throws IOException {
        if (!repository.exists(backupLoc)) {
            repository.createDirectory(backupLoc);
        }
        URI indexDir = getIndexDir();
        if (!repository.exists(indexDir)) {
            repository.createDirectory(indexDir);
        }

        URI shardBackupIdDir = getShardBackupIdDir();
        if (!repository.exists(shardBackupIdDir)) {
            repository.createDirectory(shardBackupIdDir);
        }
    }
}
