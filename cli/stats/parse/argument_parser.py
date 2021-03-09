import argparse

from rich.console import Console

from stats import io, dyn
from .rich_formatter import RichFormatter

class ArgumentParser(argparse.ArgumentParser):

    def __init__(self, *args, target=None, view=io.View, **kwds):
        super().__init__(
            *args, formatter_class=RichFormatter, **kwds
        )

        if target is not None:
            self.set_target(target)

        self.add_argument(
            "--backtrace",
            action="store_true",
            help="Print backtraces on error",
        )

        # self.add_argument(
        #     '--log',
        #     type=str,
        #     help="File path to write logs to.",
        # )

        self.add_argument(
            "-v",
            "--verbose",
            action="count",
            help="Make noise.",
        )

        self.add_argument(
            "-o",
            "--output",
            default=view.DEFAULT_FORMAT,
            help=view.help(),
        )

    def set_target(self, target):
        self.set_defaults(__target__=target)

    def action_dests(self):
        return [
            action.dest
            for action in self._actions
            if action.dest != argparse.SUPPRESS
        ]

    def add_children(self, module__name__, module__path__):
        subparsers = self.add_subparsers()

        for module in dyn.children_modules(module__name__, module__path__):
            if hasattr(module, "add_to"):
                module.add_to(subparsers)

    def format_rich_help(self):
        formatter = self._get_formatter()

        # usage
        formatter.add_usage(self.usage, self._actions,
                            self._mutually_exclusive_groups)

        # description
        formatter.add_text(self.description)

        # positionals, optionals and user-defined groups
        for action_group in self._action_groups:
            formatter.start_section(action_group.title)
            formatter.add_text(action_group.description)
            formatter.add_arguments(action_group._group_actions)
            formatter.end_section()

        # epilog
        formatter.add_text(self.epilog)

        # determine help from format above
        return formatter.format_rich()

    def format_help(self) -> str:
        return io.render_to_string(self.format_rich_help())

    def print_help(self, file=None):
        if file is None:
            console = io.OUT
        elif isinstance(file, Console):
            console = file
        else:
            console = Console(file=file)
        console.print(self.format_rich_help())

