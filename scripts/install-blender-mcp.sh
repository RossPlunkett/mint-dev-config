#!/usr/bin/env bash
set -euo pipefail

# The Blender addon and MCP server come from the same pinned package, so they
# stay in step. dotfiles/mcp/mcp.json gives Pi the same server.
export PATH="$HOME/.local/bin:$PATH"
package=mcp-for-blender==2.1.9
addons="$HOME/.config/blender/5.2/scripts/addons"

mkdir -p "$addons"
uvx "$package" install-addon --addons-dir "$addons"
blender --background --python-expr \
    "import addon_utils, bpy; addon_utils.enable('blender_mcp', default_set=True, persistent=True); bpy.ops.wm.save_userpref()"
claude mcp remove --scope user blender >/dev/null 2>&1 || true
claude mcp add --scope user blender -- uvx "$package"
