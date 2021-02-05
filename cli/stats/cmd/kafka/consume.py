import json

from kafka import KafkaConsumer

from stats import log as logging

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "consume",
        help="Consume a Kafka topic",
    )
    parser.add_argument(
        "-t",
        "--topic",
        default="events",
        help="Kafka topic to consume",
    )
    parser.set_defaults(func=run)


def run(topic, **_kwds):
    consumer = KafkaConsumer(
        topic,
        bootstrap_servers=["localhost:9091"],
        value_deserializer=json.loads,
        auto_offset_reset="earliest",
    )
    for record in consumer:
        LOG.info("Consumed record", **record._asdict())