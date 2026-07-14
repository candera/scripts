# import adsk.core
# import traceback

# _app = None
# _ui = None

# def run(context):
#     global _app, _ui
#     try:
#         _app = adsk.core.Application.get()
#         _ui = _app.userInterface
#         _ui.messageBox('ActivateComponentByName: run() was called.')
#     except:
#         # last-ditch error reporting
#         app = adsk.core.Application.get()
#         if app:
#             ui = app.userInterface
#             ui.messageBox('Add-in failed in run():\n{}'.format(traceback.format_exc()))

# def stop(context):
#     global _app, _ui
#     try:
#         if _ui:
#             _ui.messageBox('ActivateComponentByName: stop() was called.')
#     except:
#         pass


import adsk.core
import adsk.fusion
import traceback

# Global references so event handlers don't get GC'd
_app = None
_ui = None
_handlers = []

CMD_ID = 'ActivateComponentByName_Command'
CMD_NAME = 'Activate Component By Name'
CMD_DESCRIPTION = 'Activate a component by typing part of its name.'

# UI placement
WORKSPACE_ID = 'FusionSolidEnvironment'
TAB_ID = 'ToolsTab'
PANEL_ID = 'SolidScriptsAddinsPanel'

# Global caches for matches
_all_occurrences = []   # list[(Occurrence, label)]
_current_matches = []   # list[(Occurrence, label)] aligned with dropdown items


# def run(context):
#     global _app, _ui
#     try:
#         _app = adsk.core.Application.get()
#         _ui = _app.userInterface
#         _ui.messageBox('ActivateComponentByName: run() was called.')
#     except:
#         # last-ditch error reporting
#         app = adsk.core.Application.get()
#         if app:
#             ui = app.userInterface
#             ui.messageBox('Add-in failed in run():\n{}'.format(traceback.format_exc()))

# def stop(context):
#     global _app, _ui
#     try:
#         if _ui:
#             _ui.messageBox('ActivateComponentByName: stop() was called.')
#     except:
#         pass


def run(context):
    global _app, _ui
    try:
        _app = adsk.core.Application.get()
        _ui = _app.userInterface

        _ui.messageBox('ActivateComponentByName: about to call run().')
        create_command_definition()
        my_add_command_to_ui()
        _ui.messageBox('ActivateComponentByName: run() was called.')

    except:
        if _ui:
            _ui.messageBox('Failed in run:\n{}'.format(traceback.format_exc()))


def stop(context):
    global _app, _ui
    try:
        _app = adsk.core.Application.get()
        _ui = _app.userInterface

        remove_command_from_ui()
        delete_command_definition()

    except:
        if _ui:
            _ui.messageBox('Failed in stop:\n{}'.format(traceback.format_exc()))


# ---------- UI setup helpers ----------

def create_command_definition():
    """
    Create the CommandDefinition if it doesn't already exist.
    """
    cmd_defs = _ui.commandDefinitions
    cmd_def = cmd_defs.itemById(CMD_ID)
    if cmd_def:
        return

    cmd_def = cmd_defs.addButtonDefinition(
        CMD_ID,
        CMD_NAME,
        CMD_DESCRIPTION,
        ''  # resourceFolder, leave empty if you don't have icons
    )

    on_created = CommandCreatedHandler()
    cmd_def.commandCreated.add(on_created)
    _handlers.append(on_created)


def delete_command_definition():
    cmd_def = _ui.commandDefinitions.itemById(CMD_ID)
    if cmd_def:
        cmd_def.deleteMe()


def my_add_command_to_ui():
    """
    Put the command button in the Design workspace, Tools tab, ADD-INS panel.
    Uses the 1-argument addCommand overload for robustness.
    """
    _ui.messageBox('ActivateComponentByName: a.')
    workspace = _ui.workspaces.itemById(WORKSPACE_ID)
    if not workspace:
        return
    _ui.messageBox('ActivateComponentByName: a.1.')

    tab = workspace.toolbarTabs.itemById(TAB_ID)
    if not tab:
        return
    _ui.messageBox('ActivateComponentByName: a.2.')

    panel = tab.toolbarPanels.itemById(PANEL_ID)
    if not panel:
        return
    _ui.messageBox('ActivateComponentByName: a.3.')

    # Avoid duplicates
    existing = panel.controls.itemById(CMD_ID)
    if existing:
        return
    _ui.messageBox('ActivateComponentByName: b.')

    cmd_def = _ui.commandDefinitions.itemById(CMD_ID)
    if not cmd_def:
        return

    ctrl = panel.controls.addCommand(cmd_def)

    ctrl.isPromoted = True
    ctrl.isPromotedByDefault = True
    _ui.messageBox('ActivateComponentByName: c.')



def remove_command_from_ui():
    workspace = _ui.workspaces.itemById(WORKSPACE_ID)
    if not workspace:
        return

    tab = workspace.toolbarTabs.itemById(TAB_ID)
    if not tab:
        return

    panel = tab.toolbarPanels.itemById(PANEL_ID)
    if not panel:
        return

    ctrl = panel.controls.itemById(CMD_ID)
    if ctrl:
        ctrl.deleteMe()


# ---------- Event handlers ----------

class CommandCreatedHandler(adsk.core.CommandCreatedEventHandler):
    def notify(self, args: adsk.core.CommandCreatedEventArgs):
        global _all_occurrences, _current_matches

        try:
            cmd = args.command
            inputs = cmd.commandInputs

            # Text input for filtering
            query_input = inputs.addStringValueInput(
                'componentQuery',
                'Filter',
                ''
            )

            # Dropdown to show live matches (text list style)
            try:
                style = adsk.core.DropDownStyles.TextListDropDownStyle
            except AttributeError:
                # Fallback for odd builds: 0 usually maps to default style
                style = 0

            match_list = inputs.addDropDownCommandInput(
                'componentMatches',
                'Matches',
                style
            )
            try:
                match_list.isFullWidth = True
            except:
                pass

            # Build full occurrence list once for this command instance
            _all_occurrences = gather_all_occurrences()
            _current_matches = _all_occurrences[:]  # start with everything

            # Populate initial list
            rebuild_match_list('', match_list)

            # Hook events
            on_execute = CommandExecuteHandler()
            cmd.execute.add(on_execute)
            _handlers.append(on_execute)

            on_input_changed = CommandInputChangedHandler()
            cmd.inputChanged.add(on_input_changed)
            _handlers.append(on_input_changed)

            on_validate = CommandValidateInputsHandler()
            cmd.validateInputs.add(on_validate)
            _handlers.append(on_validate)

        except:
            if _ui:
                _ui.messageBox('Failed in CommandCreatedHandler:\n{}'.format(
                    traceback.format_exc()
                ))


# class CommandInputChangedHandler(adsk.core.CommandInputChangedEventHandler):
#     def notify(self, args: adsk.core.CommandInputChangedEventArgs):
#         try:
#             cmd = args.command
#             inputs = cmd.commandInputs
#             changed = args.input

#             if changed.id == 'componentQuery':
#                 query_input = adsk.core.StringValueCommandInput.cast(changed)
#                 list_input = adsk.core.DropDownCommandInput.cast(
#                     inputs.itemById('componentMatches')
#                 )
#                 rebuild_match_list(query_input.value, list_input)

#         except:
#             if _ui:
#                 _ui.messageBox('Failed in CommandInputChangedHandler:\n{}'.format(
#                     traceback.format_exc()
#                 ))


# class CommandValidateInputsHandler(adsk.core.ValidateInputsEventHandler):
#     def notify(self, args: adsk.core.ValidateInputsEventArgs):
#         try:
#             cmd = args.command
#             inputs = cmd.commandInputs

#             list_input = adsk.core.DropDownCommandInput.cast(
#                 inputs.itemById('componentMatches')
#             )

#             # OK is enabled only if there is at least one match
#             args.areInputsValid = (
#                 list_input is not None and
#                 list_input.listItems.count > 0
#             )

#         except:
#             if _ui:
#                 _ui.messageBox('Failed in CommandValidateInputsHandler:\n{}'.format(
#                     traceback.format_exc()
#                 ))


# class CommandExecuteHandler(adsk.core.CommandEventHandler):
#     def notify(self, args: adsk.core.CommandEventArgs):
#         global _current_matches

#         try:
#             cmd = args.command
#             inputs = cmd.commandInputs

#             list_input = adsk.core.DropDownCommandInput.cast(
#                 inputs.itemById('componentMatches')
#             )

#             selected_item = list_input.selectedItem if list_input else None

#             if not selected_item:
#                 # If nothing is explicitly selected, fall back to first match (if any)
#                 if _current_matches:
#                     occ, label = _current_matches[0]
#                     activate_occurrence(occ, label, show_message=False)
#                 else:
#                     _ui.messageBox('No component selected or matched.')
#                 return

#             idx = selected_item.index
#             if idx < 0 or idx >= len(_current_matches):
#                 _ui.messageBox('Selected index is out of range.')
