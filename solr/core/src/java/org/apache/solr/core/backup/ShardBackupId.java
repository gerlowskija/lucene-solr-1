package org.apache.solr.core.backup;

/**
 * Uniquely identifies a shard-backup
 */
public class ShardBackupId {
    private final String shardName;
    private final BackupId containingBackupId;

    public ShardBackupId(String shardName, BackupId containingBackupId) {
        this.shardName = shardName;
        this.containingBackupId = containingBackupId;
    }

    public String getShardName() {
        return shardName;
    }

    public BackupId getContainingBackupId() {
        return containingBackupId;
    }

    //JEGERLOW TODO At the tail end of refactoring, see whether I can eliminate uses of this method
    public String getIdAsString() {
        return "md_" + shardName + "_" + containingBackupId.getId();
    }

    public static ShardBackupId from(String idString) {
        final String[] idComponents = idString.split("_");
        if (idComponents.length != 3) {
            throw new IllegalArgumentException("Unable to parse invalid ShardBackupId: " + idString);
        }

        final BackupId containingBackupId = new BackupId(Integer.parseInt(idComponents[2]));
        return new ShardBackupId(idComponents[1], containingBackupId);
    }
}
