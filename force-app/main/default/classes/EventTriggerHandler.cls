public class EventTriggerHandler {
    /**
     * Validates meetings for overlapping and weekend scheduling.
     * @param newEvents List of Event records being inserted or updated.
     */
    public static void validateMeetings(List<Event> newEvents) {
        //fetch existing events for overlapping validation
        Set<Id> eventIds = new Set<Id>();
        for(Event ev : newEvents){
            if(ev.Id != null){
                eventIds.add(ev.Id);
            }
        }

        List<Event> existingEvents = [
            SELECT Id, StartDateTime, EndDateTime
            FROM Event
            WHERE Id IN :eventIds
        ];

        for(Event newEvent : newEvents){
            //validate weekend scheduling
            validateWeekend(newEvent);

            //validate overlapping events
            validateOverlap(newEvent, existingEvents);
        }
    } 

    /**
     * Validates that the event is not scheduled on a weekend.
     * @parm newEvent Event record being validated
     */
    private static void validateWeekend(Event newEvent){
        if(newEvent.StartDateTime != null){
            Date eventDate = newEvent.StartDateTime.date();
            Integer dayOfWeek = eventDate.toStartOfWeek().daysBetween(eventDate);

            if(dayOfWeek == 5 || dayOfWeek == 6){//saturday or sunday
                newEvent.addError('Meetings cannont be scheduled on weekends.');
            }
        }
    }

    /**
     * Validates that the new event does not overlap with existing events.
     * @param newEvent Event record being validated
     * @param existingEvents List of existing Event records
     */

     private static void validateOverlap(Event newEvent, List<Event> existingEvents) {
        for(Event existingEvent : existingEvents){
            if(newEvent.StartDateTime != null && newEvent.EndDateTime != null && existingEvent.StartDateTime != null && existingEvent.EndDateTime != null){

                //check for overlap
                if((newEvent.StartDateTime < existingEvent.EndDateTime)&&(newEvent.EndDateTime > existingEvent.StartDateTime)){
                    newEvent.addError('This meeting overlaps with an existing meeting.');
                }
            }
        }
     }
}