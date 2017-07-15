-- Copied from https://gist.githubusercontent.com/dulm/ee5ec47cfd2a71ded0e3841ee04e6ea3/raw/79668615f709960c39846149eacebe7db743c948/init.lua
modal = hs.hotkey.modal.new({}, nil )

delay = hs.eventtap.keyRepeatDelay()

function bindKeyMappers(keyMappers,modal)
  for i,mapper in ipairs(keyMappers) do
    if modal == nil then
      hs.hotkey.bind(mapper[1], mapper[2], function()
        hs.eventtap.keyStroke(mapper[3],mapper[4])
      end)
    else
      modal:bind(mapper[1], mapper[2], function()
        modal.triggered = true
        hs.eventtap.keyStroke(mapper[3],mapper[4])
      end, nil, function()
        modal.triggered = true
        hs.eventtap.keyStroke(mapper[3],mapper[4], delay)
      end)
    end
  end
end

defaultKeyMappers = {
  {{'ctrl'},'w',{'cmd'},'x'}, --剪切
  {{'alt'},'w',{'cmd'},'c'}, --复制
  {{'ctrl'},'y',{'cmd'},'v'}, --粘贴
  {{"ctrl","shift"},'-',{'cmd'},'z'}, --撤销
  {{'ctrl'},'v',{},'pagedown'}, --剪切
  {{'alt'},'v',{},'pageup'}, --复制

  {{'ctrl'},'n',{},'down'},
  {{'ctrl'},'p',{},'up'}, 
  
  {{'alt','shift'},',',{'cmd'},'up'}, --文首
  {{'alt','shift'},'.',{'cmd'},'down'}, --文末

  {{'ctrl'},'s',{'cmd'},'f'}, --查找

  {{'alt'},'f',{'alt'},'right'}, --前移一词
  {{'alt'},'b',{'alt'},'left'}, --后移一词
}

appKeyMappers = {
  Evernote = {
    {{'ctrl'},'w',{'cmd'},'x'}, --剪切
    {{'alt'},'w',{'cmd'},'c'}, --复制
    {{'ctrl'},'y',{'cmd'},'v'}, --粘贴
    {{"ctrl","shift"},'-',{'cmd'},'z'}, --撤销
    {{'ctrl'},'v',{},'pagedown'}, --剪切
    {{'alt'},'v',{},'pageup'}, --复制


    {{'ctrl','shift'},',',{'cmd'},'up'}, --文首
    {{'ctrl','shift'},'.',{'cmd'},'down'}, --文末
    {{'ctrl'},'s',{'cmd'},'f'}, --查找
    {{'alt'},'f',{'alt'},'right'}, --前移一词
    {{'alt'},'b',{'alt'},'left'}, --后移一词

    {{'ctrl','shift'},'v',{'cmd','shift'},'v'}, --去格式粘贴
    {{'ctrl','shift'},'s',{'cmd'},'s'}, --保存
    {{'ctrl','shift'},'a',{'cmd'},'a'}, --全选

  },

  Firefox =
  --"nochange",

  {
    {{"ctrl","shift"},'-',{'cmd'},'z'}, --撤销
    {{'alt'},'w',{'cmd'},'c'}, --复制
    {{'ctrl'},'y',{'cmd'},'v'}, --粘贴
    {{'alt'},'f',{'alt'},'right'}, --前移一词
    {{'alt'},'b',{'alt'},'left'}, --后移一词
  },

  ["VMware Fusion"] = "nochange",
  ["Sublime Text"] = "nochange",
  ["IntelliJ IDEA"] = "nochange",
  ["Emacs"] = "nochange",
}

function applicationWatcher(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    print(appName)
    local isMatch = false
    for app, keyMappers in pairs(appKeyMappers) do
      if(appName == app) then
        if keyMappers == "nochange" then
          modal:exit()
        else
          modal:exit()
          bindKeyMappers(keyMappers,modal)
          modal:enter()
        end
        isMatch = true
        break
      end
    end
    if isMatch == false then
      modal:exit()
      bindKeyMappers(defaultKeyMappers,modal)
      modal:enter()
    end
  end
end
local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()



-- Reload config when any lua file in config directory changes
function reloadConfig(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == '.lua' then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end
local myWatcher = hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()
hs.alert.show('Config loaded')
