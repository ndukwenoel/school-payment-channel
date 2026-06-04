from .schemas import BaseEvent
from worker.tasks import process_domain_event

class EventDispatcher:
    @staticmethod
    def publish(event: BaseEvent):
        """
        Publishes an event to the background task queue.
        In a full Kafka/RabbitMQ setup, this would publish to an exchange.
        For now, we route it directly to our Celery task queue.
        """
        print(f"Publishing event {event.event_type} [ID: {event.event_id}]")
        # Serialize the pydantic model to a dict for Celery
        # .dict() is used for wider pydantic compatibility depending on v1/v2
        event_data = event.dict()
        
        # Dispatch to Celery worker asynchronously
        process_domain_event.delay(event_data)
