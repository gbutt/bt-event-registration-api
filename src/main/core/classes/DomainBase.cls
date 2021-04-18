/**
 * @author Greg Butt
 * @date 2021
 *
 * @group Core
 *
 * @description Base class extended by all Domain classes. See https://trailhead.salesforce.com/en/content/learn/modules/apex_patterns_dsl
 */
public with sharing abstract class DomainBase {
    protected TriggerOperation operationType {get; private set;}
    public DomainBase(TriggerOperation operationType) {
        this.operationType = operationType;
    }

    public abstract Boolean isDisabled();

    public virtual void beforeInsert() {}
    public virtual void afterInsert() {}
    public virtual void beforeUpdate() {}
    public virtual void afterUpdate() {}
    public virtual void beforeDelete() {}
    public virtual void afterDelete() {}
    public virtual void afterUndelete() {}

    public void execute() {
        if (isDisabled() == true) {
            return;
        }
        switch on this.operationType {
            when BEFORE_INSERT {
                this.beforeInsert();
            }
            when AFTER_INSERT {
                this.afterInsert();
            }
            when BEFORE_UPDATE {
                this.beforeUpdate();
            }
            when AFTER_UPDATE {
                this.afterUpdate();
            }
            when BEFORE_DELETE {
                this.beforeDelete();
            }
            when AFTER_DELETE {
                this.afterDelete();
            }
            when AFTER_UNDELETE {
                this.afterUndelete();
            }
        }
    }

    public static string createUuid() {
        Blob b = Crypto.generateAesKey(128);
        String key = EncodingUtil.convertToHex(b);
        return key.substring(0, 8) + '-' +
               key.substring(8, 12) + '-' +
               key.substring(12, 16) + '-' +
               key.substring(16, 20) + '-' +
               key.substring(20);
    }
}