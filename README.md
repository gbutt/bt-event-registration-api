# Event Registration API - Code Challenge

## Setup Instructions

1. If you have a namespace, edit it in:
    1. sfdx-project.json
    1. scripts/testApi.sh
1. Create new scratch org and push
1. Grant yourself the Event Admin permission set: `sfdx force:user:permset:assign --permsetname=Event_Admin_Access`
1. Open scratch org and create new public site
    1. Grant permission set to guest user: `Event_API_Access`
    1. Update SFDC_HOST var in `scripts/testApi.sh` with site domain
1. Test public api with ping. See `scripts/testApi.sh`
1. Grant permission set `Event_Admin_Access` to Event Administrators
    1. Administrators can manage all events
1. Grant permission set `Event_User_Access` to Event Users
    1. Users can manage their own events

## Test Instructions

1. Open the Acme Event app and create a real event. Invite some registrants. Change the status to Open.
1. Test the Registration API
    1. Create a registration with email = 'phumperdink@florin.co'. Status should be Invited.
    1. Run bash script `./scripts/testApi.sh ${eventUuid}`
    1. Check registration and ensure status is changed to Registered.
1. Change the event status to Completed
    1. All non-registered registrants should have the "No Show" flag checked.
    1. Event stats in the highlights panel are updated to reflect total/invited/registered/no show
