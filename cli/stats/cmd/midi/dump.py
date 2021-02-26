import sys
import time

from rtmidi.midiutil import open_midiinput

from stats import log as logging, io

LOG = logging.getLogger(__name__)


class MidiInputHandler:
    def __init__(self, port):
        self.port = port
        self._wallclock = time.time()

    def __call__(self, event, data=None):
        message, deltatime = event
        # channel, note, velocity = message
        self._wallclock += deltatime
        # print("[%s] @%0.6f %r" % (self.port, self._wallclock, [channel, note, velocity]))
        LOG.info(
            "MIDI message received",
            port=self.port,
            clock=self._wallclock,
            # message=dict(
            #     channel=channel,
            #     note=note,
            #     velocity=velocity,
            # )
            message=message,
        )


_PORT_HELP = (
    """MIDI port to read from, use `list` command to see what's available"""
)


def add_to(subparsers):
    parser = subparsers.add_parser(
        "dump", target=run, help="Dump events from a MIDI input to the console"
    )

    parser.add_argument("port", help=_PORT_HELP)


def run(port):
    LOG.info("[holup]Opening MIDI port...[/holup]", port=port)
    midi_in, port_name = open_midiinput(port)

    LOG.info(
        "[holup]Attaching MIDI input callback handler...[/holup]",
        port_name=port_name,
    )
    midi_in.set_callback(MidiInputHandler(port_name))

    LOG.info("[holup]Entering main loop. Press Control-C to exit...[/holup]")
    try:
        # Just wait for keyboard interrupt,
        # everything else is handled via the input callback.
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print()
    finally:
        LOG.info("[holup]Exiting...[/holup]")
        midi_in.close_port()
        del midi_in
        LOG.info("[yeah]Done.[/yeah]")
