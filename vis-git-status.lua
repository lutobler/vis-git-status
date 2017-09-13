local git_branch = '\xee\x82\xa0'
local arrow_up = '\xe2\x86\x91'
local arrow_down = '\xe2\x86\x93'

-- get the current git branch when opening a file
-- this needs to be done when opening a file (once), because the shell
-- script is somewhat expensive.
local branch_info = {}
local function update_branch_info(file)
    if not file.name then return end
    local fname = file.name
    local script = [[
        pushd . > /dev/null
        cd $(dirname "$PWD/]] .. fname .. [=[")
        [[ -d ".git" ]] || exit 1
        git_eng="env LANG=C git"
        arrow_up='__ARROW_UP'
        arrow_down='__ARROW_DOWN'
        branch=$($git_eng symbolic-ref --short HEAD 2>/dev/null)
        mod=$($git_eng status --porcelain)
        modified=
        [[ -n "$mod" ]] && modified=" (+)"
        out="$branch$modified"
        stat="$($git_eng status --porcelain --branch | grep '^##' | grep -o '\[.\+\]$')"
        aheadN="$(echo $stat | grep -o 'ahead [[:digit:]]\+' | grep -o '[[:digit:]]\+')"
        behindN="$(echo $stat | grep -o 'behind [[:digit:]]\+' | grep -o '[[:digit:]]\+')"
        [[ -n "$behindN" ]] && out+=" $behindN$arrow_down"
        [[ -n "$aheadN" ]] && out+=" $aheadN$arrow_up"
        popd > /dev/null
        [[ -n "$branch" ]] && echo "__GIT_BRANCH $out"
    ]=]

    local p = io.popen(script)
    local r = p:read("*a")
        :gsub("\n", "")                   -- remove trailing newline
        :gsub("__GIT_BRANCH", git_branch) -- insert git branch unicode character
        :gsub("__ARROW_UP", arrow_up)     -- insert arrow up unicode character
        :gsub("__ARROW_DOWN", arrow_down) -- insert arrow down unicode character
    p:close()
    if r ~= "" then
        branch_info[fname] = r
    end
end

vis.events.subscribe(vis.events.FILE_OPEN, update_branch_info)
vis.events.subscribe(vis.events.FILE_SAVE_POST, update_branch_info)

-- mostly taken from vis-std.lua
vis.events.subscribe(vis.events.WIN_STATUS, function(win)
    local left_parts = {}
    local right_parts = {}
    local file = win.file
    local selection = win.selection

    local modes = {
        [vis.modes.NORMAL] = 'NORMAL',
        [vis.modes.OPERATOR_PENDING] = '',
        [vis.modes.VISUAL] = 'VISUAL',
        [vis.modes.VISUAL_LINE] = 'VISUAL-LINE',
        [vis.modes.INSERT] = 'INSERT',
        [vis.modes.REPLACE] = 'REPLACE',
    }

    local mode = modes[vis.mode]
    if mode ~= '' and vis.win == win then
        table.insert(left_parts, mode)
    end

    -- git branch
    local branch = branch_info[file.name]
    if branch then
        table.insert(left_parts, branch)
    end

    table.insert(left_parts, (file.name or '[No Name]') ..
        (file.modified and '[+]' or '') .. (vis.recording and ' @' or ''))

    if #win.selections > 1 then
        table.insert(right_parts, selection.number .. '/' .. #win.selections)
    end

    local size = file.size
    local pos = selection.pos
    if not pos then pos = 0 end
    table.insert(right_parts,
        (size == 0 and "0" or math.ceil(pos/size*100)) .. "%")

    if not win.large then
        local col = selection.col
        table.insert(right_parts, selection.line .. ',' .. col)
        if size > 33554432 or col > 65536 then
            win.large = true
        end
    end

    local left = ' ' .. table.concat(left_parts, " » ") .. ' '
    local right = ' ' .. table.concat(right_parts, " « ") .. ' '
    win:status(left, right)
end)
