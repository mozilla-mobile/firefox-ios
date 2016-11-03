/*! Inbox campaign status. */
typedef enum {
    /*! Hasn't been seen by the user. */
    SWRVE_CAMPAIGN_STATUS_UNSEEN  = 0x1,
    
    /*! Seen at least once by the user. */
    SWRVE_CAMPAIGN_STATUS_SEEN    = 0x2,
    
    /*! Deleted and won't appear again in the Inbox. */
    SWRVE_CAMPAIGN_STATUS_DELETED = 0x3
} SwrveCampaignStatus;
