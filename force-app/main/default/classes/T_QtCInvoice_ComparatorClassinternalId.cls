public class T_QtCInvoice_ComparatorClassinternalId implements Comparable {
    public QtC_Mig_Invoice_Temp_Table__c tempTableRecord { get; set; }
    
    public T_QtCInvoice_ComparatorClassinternalId(QtC_Mig_Invoice_Temp_Table__c record) {
        tempTableRecord = record;
    }
    public Integer compareTo(Object compareTo) {
        T_QtCInvoice_ComparatorClassinternalId compareRecord = (T_QtCInvoice_ComparatorClassinternalId)compareTo;
        if (tempTableRecord.Internal_ID__c < compareRecord.tempTableRecord.Internal_ID__c) {
            return 1;
        } else if (tempTableRecord.Internal_ID__c > compareRecord.tempTableRecord.Internal_ID__c) {
            return -1;
        } else {
            return 0;
        }
    }
}