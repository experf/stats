import json

from kafka import KafkaConsumer, TopicPartition

from stats import io, log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    parser = subparsers.add_parser(
        "consume",
        help="Consume a Kafka topic",
    )
    # parser.add_argument("-t", "--topic", )
    parser.set_defaults(func=run)


def run(_args):
    consumer = KafkaConsumer(
        'events',
        bootstrap_servers=["localhost:9091"],
        value_deserializer=json.loads,
        auto_offset_reset="earliest",
    )
    for message in consumer:
        LOG.info("EVENT", message=message)
