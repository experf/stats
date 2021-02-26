# from rtmidi import MidiIn # pylint: disable=no-name-in-module
from rtmidi.midiutil import list_input_ports

from stats import log as logging

LOG = logging.getLogger(__name__)

def add_to(subparsers):
    subparsers.add_parser(
        "list",
        target=run,
        help="List available MIDI inputs"
    )

def run():
    # return MidiIn().get_ports()
    return list_input_ports()

