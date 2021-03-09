from typing import *
import re as _re
import shutil as _shutil
from gettext import gettext as _

from argparse import (
    SUPPRESS,
    OPTIONAL,
    ZERO_OR_MORE,
    ONE_OR_MORE,
    REMAINDER,
    PARSER
)

from rich.syntax import Syntax
from rich.text import Text
from rich.console import RenderGroup
from rich.panel import Panel
from rich.style import Style
from rich.markdown import Markdown

from stats import io

class RichFormatter(object):
    """Formatter for `argparse.ArgumentParser` using `rich`.

    Adapted from `argparse.HelpFormatter`.
    """

    def __init__(self, prog):
        self._prog = prog

        self._root_section = self._Section(self, None)
        self._current_section = self._root_section

    def _add_item(self, func, args):
        self._current_section.items.append((func, args))

    # ===============================
    # Section and indentation methods
    # ===============================

    class _Section(object):

        def __init__(self, formatter, parent, heading=None):
            self.formatter = formatter
            self.parent = parent
            self.heading = heading
            self.items = []
            if parent is None:
                self.level = 1
            else:
                self.level = 1 + parent.level

        @property
        def title(self) -> Optional[str]:
            if self.heading is not SUPPRESS and self.heading is not None:
                return self.heading
            return None

        @property
        def renderable_items(self):
            return list(filter(
                lambda x: x is not None,
                (func(*args) for func, args in self.items)
            ))

        @property
        def render_group(self) -> Optional[RenderGroup]:
            return RenderGroup(*self.renderable_items)

        def format_rich(self):
            group = self.render_group

            if self.parent is None:
                return group

            if len(group.renderables) == 0:
                return None

            return Panel(group, title=self.title)

        def format_help(self):
            raise "HERE"
            return self.renderable

    # ========================
    # Message building methods
    # ========================

    def start_section(self, heading):
        section = self._Section(self, self._current_section, heading)
        self._add_item(section.format_rich, [])
        self._current_section = section

    def end_section(self):
        self._current_section = self._current_section.parent

    def add_text(self, text):
        if text is not SUPPRESS and text is not None:
            self._add_item(self._format_text, [text])

    def add_usage(self, usage, actions, groups, prefix="Usage"):
        if usage is not SUPPRESS:
            args = usage, actions, groups
            if prefix != "":
                self._add_item(self._format_heading, [prefix])
            self._add_item(self._format_usage, args)

    def add_argument(self, action):
        if action.help is not SUPPRESS:

            # find all invocations
            get_invocation = self._format_action_invocation
            invocations = [get_invocation(action)]
            for subaction in self._iter_subactions(action):
                invocations.append(get_invocation(subaction))

            # add the item to the list
            self._add_item(self._format_action, [action])

    def add_arguments(self, actions):
        for action in actions:
            self.add_argument(action)

    # =======================
    # Help-formatting methods
    # =======================

    def format_rich(self):
        return self._root_section.format_rich()

    def format_help(self):
        return io.render_to_string(self.format_rich())

    def _format_heading(self, heading):
        return Text(heading, style="bold red")

    def _format_usage(self, usage, actions, groups):
        # if usage is specified, use that
        if usage is not None:
            usage = usage % dict(prog=self._prog)

        # if no optionals or positionals are available, usage is just prog
        elif usage is None and not actions:
            usage = '%(prog)s' % dict(prog=self._prog)

        # if optionals and positionals are available, calculate usage
        elif usage is None:
            prog = '%(prog)s' % dict(prog=self._prog)

            # split optionals from positionals
            optionals = []
            positionals = []
            for action in actions:
                if action.option_strings:
                    optionals.append(action)
                else:
                    positionals.append(action)

            # build full usage string
            format = self._format_actions_usage
            action_usage = format(optionals + positionals, groups)
            usage = ' '.join([s for s in [prog, action_usage] if s])

        # https://rich.readthedocs.io/en/latest/reference/syntax.html
        return Syntax(usage, "bash")

    def _format_text(self, text):
        if '%(prog)' in text:
            text = text % dict(prog=self._prog)
        return Text(text)

    def _iter_subactions(self, action):
        try:
            get_subactions = action._get_subactions
        except AttributeError:
            pass
        else:
            yield from get_subactions()

    def _metavar_formatter(self, action, default_metavar):
        if action.metavar is not None:
            result = action.metavar
        elif action.choices is not None:
            choice_strs = [str(choice) for choice in action.choices]
            result = '{%s}' % ','.join(choice_strs)
        else:
            result = default_metavar

        def format(tuple_size):
            if isinstance(result, tuple):
                return result
            else:
                return (result, ) * tuple_size
        return format

    def _format_args(self, action, default_metavar):
        get_metavar = self._metavar_formatter(action, default_metavar)
        if action.nargs is None:
            result = '%s' % get_metavar(1)
        elif action.nargs == OPTIONAL:
            result = '[%s]' % get_metavar(1)
        elif action.nargs == ZERO_OR_MORE:
            result = '[%s [%s ...]]' % get_metavar(2)
        elif action.nargs == ONE_OR_MORE:
            result = '%s [%s ...]' % get_metavar(2)
        elif action.nargs == REMAINDER:
            result = '...'
        elif action.nargs == PARSER:
            result = '%s ...' % get_metavar(1)
        elif action.nargs == SUPPRESS:
            result = ''
        else:
            try:
                formats = ['%s' for _ in range(action.nargs)]
            except TypeError:
                raise ValueError("invalid nargs value") from None
            result = ' '.join(formats) % get_metavar(action.nargs)
        return result

    def _get_default_metavar_for_positional(self, action):
        return action.dest

    def _format_action_invocation(self, action):
        if not action.option_strings:
            default = self._get_default_metavar_for_positional(action)
            metavar, = self._metavar_formatter(action, default)(1)
            return metavar

        else:
            parts = []

            # if the Optional doesn't take a value, format is:
            #    -s, --long
            if action.nargs == 0:
                parts.extend(action.option_strings)

            # if the Optional takes a value, format is:
            #    -s ARGS, --long ARGS
            else:
                default = self._get_default_metavar_for_optional(action)
                args_string = self._format_args(action, default)
                for option_string in action.option_strings:
                    parts.append('%s %s' % (option_string, args_string))

            return ', '.join(parts)

    def _format_action(self, action):
        # determine the required width and the entry label
        action_header = self._format_action_invocation(action)

        # collect the pieces of the action help
        parts = [action_header]

        # if there was help for the action, add lines of help text
        if action.help:
            help_text = self._expand_help(action)
            parts.append(help_text)

        # if there are any sub-actions, add their help as well
        for subaction in self._iter_subactions(action):
            parts.append(self._format_action(subaction))

        # return a render group
        return RenderGroup(*parts)

    def _get_default_metavar_for_optional(self, action):
        return action.dest.upper()

    def _expand_help(self, action):
        params = dict(vars(action), prog=self._prog)
        for name in list(params):
            if params[name] is SUPPRESS:
                del params[name]
        for name in list(params):
            if hasattr(params[name], '__name__'):
                params[name] = params[name].__name__
        if params.get('choices') is not None:
            choices_str = ', '.join([str(c) for c in params['choices']])
            params['choices'] = choices_str
        return Markdown(self._get_help_string(action) % params)

    def _get_help_string(self, action):
        return action.help

    def _format_actions_usage(self, actions, groups):
        # find group indices and identify actions in groups
        group_actions = set()
        inserts = {}
        for group in groups:
            try:
                start = actions.index(group._group_actions[0])
            except ValueError:
                continue
            else:
                end = start + len(group._group_actions)
                if actions[start:end] == group._group_actions:
                    for action in group._group_actions:
                        group_actions.add(action)
                    if not group.required:
                        if start in inserts:
                            inserts[start] += ' ['
                        else:
                            inserts[start] = '['
                        if end in inserts:
                            inserts[end] += ']'
                        else:
                            inserts[end] = ']'
                    else:
                        if start in inserts:
                            inserts[start] += ' ('
                        else:
                            inserts[start] = '('
                        if end in inserts:
                            inserts[end] += ')'
                        else:
                            inserts[end] = ')'
                    for i in range(start + 1, end):
                        inserts[i] = '|'

        # collect all actions format strings
        parts = []
        for i, action in enumerate(actions):

            # suppressed arguments are marked with None
            # remove | separators for suppressed arguments
            if action.help is SUPPRESS:
                parts.append(None)
                if inserts.get(i) == '|':
                    inserts.pop(i)
                elif inserts.get(i + 1) == '|':
                    inserts.pop(i + 1)

            # produce all arg strings
            elif not action.option_strings:
                default = self._get_default_metavar_for_positional(action)
                part = self._format_args(action, default)

                # if it's in a group, strip the outer []
                if action in group_actions:
                    if part[0] == '[' and part[-1] == ']':
                        part = part[1:-1]

                # add the action string to the list
                parts.append(part)

            # produce the first way to invoke the option in brackets
            else:
                option_string = action.option_strings[0]

                # if the Optional doesn't take a value, format is:
                #    -s or --long
                if action.nargs == 0:
                    part = '%s' % option_string

                # if the Optional takes a value, format is:
                #    -s ARGS or --long ARGS
                else:
                    default = self._get_default_metavar_for_optional(action)
                    args_string = self._format_args(action, default)
                    part = '%s %s' % (option_string, args_string)

                # make it look optional if it's not required or in a group
                if not action.required and action not in group_actions:
                    part = '[%s]' % part

                # add the action string to the list
                parts.append(part)

        # insert things at the necessary indices
        for i in sorted(inserts, reverse=True):
            parts[i:i] = [inserts[i]]

        # join all the action items with spaces
        text = ' '.join([item for item in parts if item is not None])

        # clean up separators for mutually exclusive groups
        open = r'[\[(]'
        close = r'[\])]'
        text = _re.sub(r'(%s) ' % open, r'\1', text)
        text = _re.sub(r' (%s)' % close, r'\1', text)
        text = _re.sub(r'%s *%s' % (open, close), r'', text)
        text = _re.sub(r'\(([^|]*)\)', r'\1', text)
        text = text.strip()

        # return the text
        return text
