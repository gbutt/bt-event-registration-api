@IsTest(IsParallel = true)
public class DomainBaseTest {
    @IsTest
    static void it_should_execute_operations() {
        TestDomain domain = new TestDomain(TriggerOperation.BEFORE_INSERT);
        domain.disabled = true;
        domain.execute();
        System.assertEquals(null, domain.executedBeforeInsert);

        domain = new TestDomain(TriggerOperation.BEFORE_INSERT);
        domain.execute();
        System.assertEquals(true, domain.executedBeforeInsert);

        domain = new TestDomain(TriggerOperation.AFTER_INSERT);
        domain.execute();
        System.assertEquals(true, domain.executedAfterInsert);

        domain = new TestDomain(TriggerOperation.BEFORE_UPDATE);
        domain.execute();
        System.assertEquals(true, domain.executedBeforeUpdate);

        domain = new TestDomain(TriggerOperation.AFTER_UPDATE);
        domain.execute();
        System.assertEquals(true, domain.executedAfterUpdate);

        domain = new TestDomain(TriggerOperation.BEFORE_DELETE);
        domain.execute();
        System.assertEquals(true, domain.executedBeforeDelete);

        domain = new TestDomain(TriggerOperation.AFTER_DELETE);
        domain.execute();
        System.assertEquals(true, domain.executedAfterDelete);

        domain = new TestDomain(TriggerOperation.AFTER_UNDELETE);
        domain.execute();
        System.assertEquals(true, domain.executedAfterUndelete);
    }

    @IsTest
    static void it_should_do_nothing_by_default() {
        TestMinimalDomain domain = new TestMinimalDomain(TriggerOperation.BEFORE_INSERT);
        domain.execute();

        domain = new TestMinimalDomain(TriggerOperation.AFTER_INSERT);
        domain.execute();

        domain = new TestMinimalDomain(TriggerOperation.BEFORE_UPDATE);
        domain.execute();

        domain = new TestMinimalDomain(TriggerOperation.AFTER_UPDATE);
        domain.execute();

        domain = new TestMinimalDomain(TriggerOperation.BEFORE_DELETE);
        domain.execute();

        domain = new TestMinimalDomain(TriggerOperation.AFTER_DELETE);
        domain.execute();

        domain = new TestMinimalDomain(TriggerOperation.AFTER_UNDELETE);
        domain.execute();
        System.assert(true);
    }

    public class TestMinimalDomain extends DomainBase {
        public TestMinimalDomain(TriggerOperation operationType) {
            super(operationType);
        }
        public override Boolean isDisabled() {
            return null;
        }
    }

    public class TestDomain extends DomainBase {
        public Boolean disabled {get; set;}
        public Boolean executedBeforeInsert {get; set;}
        public Boolean executedAfterInsert {get; set;}
        public Boolean executedBeforeUpdate {get; set;}
        public Boolean executedAfterUpdate {get; set;}
        public Boolean executedBeforeDelete {get; set;}
        public Boolean executedAfterDelete {get; set;}
        public Boolean executedAfterUndelete {get; set;}

        public TestDomain(TriggerOperation operationType) {
            super(operationType);
        }

        public override Boolean isDisabled() {
            return this.disabled;
        }

        public override void beforeInsert() {
            this.executedBeforeInsert = true;
        }
        public override void afterInsert() {
            this.executedAfterInsert = true;
        }
        public override void beforeUpdate() {
            this.executedBeforeUpdate = true;
        }
        public override void afterUpdate() {
            this.executedAfterUpdate = true;
        }
        public override void beforeDelete() {
            this.executedBeforeDelete = true;
        }
        public override void afterDelete() {
            this.executedAfterDelete = true;
        }
        public override void afterUndelete() {
            this.executedAfterUndelete = true;
        }
    }
}