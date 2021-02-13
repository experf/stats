from typing import *
import json

from kafka import KafkaConsumer
from kafka.structs import TopicPartition

from stats import log as logging, cfg

LOG = logging.getLogger(__name__)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "keys",
        target=run,
        help="Some scratch-work around printing all keys from events",
    )
    parser.add_argument(
        "-t",
        "--event-type",
        help="`type` of event",
    )


def iter_key_paths(dct: Dict, /, key_path=tuple()):
    for key, value in dct.items():
        new_key_path = [*key_path, key]
        if isinstance(value, dict):
            yield from iter_key_paths(value, key_path=new_key_path)
        else:
            yield ".".join(new_key_path)


def run(event_type):
    consumer = KafkaConsumer(
        cfg.kafka.topic,
        bootstrap_servers=cfg.kafka.servers,
        value_deserializer=json.loads,
        auto_offset_reset="earliest",
    )

    partition = TopicPartition(cfg.kafka.topic, 0)

    beginning_offsets = consumer.beginning_offsets([partition])
    beginning_offset = beginning_offsets[partition]
    end_offsets = consumer.end_offsets([partition])
    end_offset = end_offsets[partition]

    LOG.info("Range", beginning_offset=beginning_offset, end_offset=end_offset)

    records = []

    for _ in range(beginning_offset, end_offset):
        record = next(consumer)
        if event_type is None:
            records.append(record)
        elif record.value["type"] == event_type:
            records.append(record)

    keys = set()

    for record in records:
        for key_path in iter_key_paths(record.value):
            keys.add(key_path)

    LOG.info("HERE", event_type=event_type, keys=sorted(keys))
