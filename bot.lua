serpent = require("serpent")
lgi = require ('lgi')
redis = require('redis')
database = Redis.connect('127.0.0.1', 6379)
notify = lgi.require('Notify')
notify.init ("Telegram updates")
chats = {}
day = 86400
bot_id = 313417862 --put BotID
sudo_users = {285318015} --put SudoID
  -----------------------------------------------------------------------------------------------
                                     -- start functions --
  -----------------------------------------------------------------------------------------------
function is_sudo(msg)
  local var = false
  for k,v in pairs(sudo_users) do
    if msg.sender_user_id_ == v then
      var = true
    end
  end
  return var
end
-----------------------------------------------------------------------------------------------
function is_admin(user_id)
    local var = false
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if admin then
	    var = true
	 end
  for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
  end
    return var
end
-----------------------------------------------------------------------------------------------
function is_vip_group(gp_id)
    local var = false
	local hashs =  'bot:vipgp:'
    local vip = database:sismember(hashs, gp_id)
	 if vip then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_owner(user_id, chat_id)
    local var = false
    local hash =  'bot:owners:'..chat_id
    local owner = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_mod(user_id, chat_id)
    local var = false
    local hash =  'bot:mods:'..chat_id
    local mod = database:sismember(hash, user_id)
	local hashs =  'bot:admins:'
    local admin = database:sismember(hashs, user_id)
	local hashss =  'bot:owners:'..chat_id
    local owner = database:sismember(hashss, user_id)
	 if mod then
	    var = true
	 end
	 if owner then
	    var = true
	 end
	 if admin then
	    var = true
	 end
    for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
	end
    return var
end
-----------------------------------------------------------------------------------------------
function is_banned(user_id, chat_id)
    local var = false
	local hash = 'bot:banned:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_muted(user_id, chat_id)
    local var = false
	local hash = 'bot:muted:'..chat_id
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
function is_gbanned(user_id)
    local var = false
	local hash = 'bot:gbanned:'
    local banned = database:sismember(hash, user_id)
	 if banned then
	    var = true
	 end
    return var
end
-----------------------------------------------------------------------------------------------
local function check_filter_words(msg, value)
  local hash = 'bot:filters:'..msg.chat_id_
  if hash then
    local names = database:hkeys(hash)
    local text = ''
    for i=1, #names do
	   if string.match(value:lower(), names[i]:lower()) and not is_mod(msg.sender_user_id_, msg.chat_id_)then
	     local id = msg.id_
         local msgs = {[0] = id}
         local chat = msg.chat_id_
        delete_msg(chat,msgs)
       end
    end
  end
end
-----------------------------------------------------------------------------------------------
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
  -----------------------------------------------------------------------------------------------
function changeChatMemberStatus(chat_id, user_id, status)
  tdcli_function ({
    ID = "ChangeChatMemberStatus",
    chat_id_ = chat_id,
    user_id_ = user_id,
    status_ = {
      ID = "ChatMemberStatus" .. status
    },
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getInputFile(file)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end
  -----------------------------------------------------------------------------------------------
function del_all_msgs(chat_id, user_id)
  tdcli_function ({
    ID = "DeleteMessagesFromUser",
    chat_id_ = chat_id,
    user_id_ = user_id
  }, dl_cb, nil)
end
  -----------------------------------------------------------------------------------------------
function getChatId(id)
  local chat = {}
  local id = tostring(id)
  
  if id:match('^-100') then
    local channel_id = id:gsub('-100', '')
    chat = {ID = channel_id, type = 'channel'}
  else
    local group_id = id:gsub('-', '')
    chat = {ID = group_id, type = 'group'}
  end
  
  return chat
end
  -----------------------------------------------------------------------------------------------
function chat_leave(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Left")
end
  -----------------------------------------------------------------------------------------------
function from_username(msg)
   function gfrom_user(extra,result,success)
   if result.username_ then
   F = result.username_
   else
   F = 'nil'
   end
    return F
   end
  local username = getUser(msg.sender_user_id_,gfrom_user)
  return username
end
  -----------------------------------------------------------------------------------------------
function chat_kick(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Kicked")
end
  -----------------------------------------------------------------------------------------------
function do_notify (user, msg)
  local n = notify.Notification.new(user, msg)
  n:show ()
end
  -----------------------------------------------------------------------------------------------
local function getParseMode(parse_mode)  
  if parse_mode then
    local mode = parse_mode:lower()
  
    if mode == 'markdown' or mode == 'md' then
      P = {ID = "TextParseModeMarkdown"}
    elseif mode == 'html' then
      P = {ID = "TextParseModeHTML"}
    end
  end
  return P
end
  -----------------------------------------------------------------------------------------------
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendContact(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, phone_number, first_name, last_name, user_id)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageContact",
      contact_ = {
        ID = "Contact",
        phone_number_ = phone_number,
        first_name_ = first_name,
        last_name_ = last_name,
        user_id_ = user_id
      },
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUserFull(user_id,cb)
  tdcli_function ({
    ID = "GetUserFull",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function vardump(value)
  print(serpent.block(value, {comment=false}))
end
-----------------------------------------------------------------------------------------------
function dl_cb(arg, data)
end
-----------------------------------------------------------------------------------------------
local function send(chat_id, reply_to_message_id, disable_notification, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function sendaction(chat_id, action, progress)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function changetitle(chat_id, title)
  tdcli_function ({
    ID = "ChangeChatTitle",
    chat_id_ = chat_id,
    title_ = title
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function edit(chat_id, message_id, reply_markup, text, disable_web_page_preview, parse_mode)
  local TextParseMode = getParseMode(parse_mode)
  tdcli_function ({
    ID = "EditMessageText",
    chat_id_ = chat_id,
    message_id_ = message_id,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessageText",
      text_ = text,
      disable_web_page_preview_ = disable_web_page_preview,
      clear_draft_ = 0,
      entities_ = {},
      parse_mode_ = TextParseMode,
    },
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function setphoto(chat_id, photo)
  tdcli_function ({
    ID = "ChangeChatPhoto",
    chat_id_ = chat_id,
    photo_ = getInputFile(photo)
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function add_user(chat_id, user_id, forward_limit)
  tdcli_function ({
    ID = "AddChatMember",
    chat_id_ = chat_id,
    user_id_ = user_id,
    forward_limit_ = forward_limit or 50
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function unpinmsg(channel_id)
  tdcli_function ({
    ID = "UnpinChannelMessage",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function blockUser(user_id)
  tdcli_function ({
    ID = "BlockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function unblockUser(user_id)
  tdcli_function ({
    ID = "UnblockUser",
    user_id_ = user_id
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function getBlockedUsers(offset, limit)
  tdcli_function ({
    ID = "GetBlockedUsers",
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function delete_msg(chatid,mid)
  tdcli_function ({
  ID="DeleteMessages", 
  chat_id_=chatid, 
  message_ids_=mid
  },
  dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function chat_del_user(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, 'Editor')
end
-----------------------------------------------------------------------------------------------
function getChannelMembers(channel_id, offset, filter, limit)
  if not limit or limit > 200 then
    limit = 200
  end
  tdcli_function ({
    ID = "GetChannelMembers",
    channel_id_ = getChatId(channel_id).ID,
    filter_ = {
      ID = "ChannelMembers" .. filter
    },
    offset_ = offset,
    limit_ = limit
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getChannelFull(channel_id)
  tdcli_function ({
    ID = "GetChannelFull",
    channel_id_ = getChatId(channel_id).ID
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
local function channel_get_bots(channel,cb)
local function callback_admins(extra,result,success)
    limit = result.member_count_
    getChannelMembers(channel, 0, 'Bots', limit,cb)
    end
  getChannelFull(channel,callback_admins)
end
-----------------------------------------------------------------------------------------------
local function getInputMessageContent(file, filetype, caption)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  local inmsg = {}
  local filetype = filetype:lower()

  if filetype == 'animation' then
    inmsg = {ID = "InputMessageAnimation", animation_ = infile, caption_ = caption}
  elseif filetype == 'audio' then
    inmsg = {ID = "InputMessageAudio", audio_ = infile, caption_ = caption}
  elseif filetype == 'document' then
    inmsg = {ID = "InputMessageDocument", document_ = infile, caption_ = caption}
  elseif filetype == 'photo' then
    inmsg = {ID = "InputMessagePhoto", photo_ = infile, caption_ = caption}
  elseif filetype == 'sticker' then
    inmsg = {ID = "InputMessageSticker", sticker_ = infile, caption_ = caption}
  elseif filetype == 'video' then
    inmsg = {ID = "InputMessageVideo", video_ = infile, caption_ = caption}
  elseif filetype == 'voice' then
    inmsg = {ID = "InputMessageVoice", voice_ = infile, caption_ = caption}
  end

  return inmsg
end

-----------------------------------------------------------------------------------------------
function send_file(chat_id, type, file, caption,wtf)
local mame = (wtf or 0)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = mame,
    disable_notification_ = 0,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = getInputMessageContent(file, type, caption),
  }, dl_cb, nil)
end
-----------------------------------------------------------------------------------------------
function getUser(user_id, cb)
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, cb, nil)
end
-----------------------------------------------------------------------------------------------
function pin(channel_id, message_id, disable_notification) 
   tdcli_function ({ 
     ID = "PinChannelMessage", 
     channel_id_ = getChatId(channel_id).ID, 
     message_id_ = message_id, 
     disable_notification_ = disable_notification 
   }, dl_cb, nil) 
end 
-----------------------------------------------------------------------------------------------
function tdcli_update_callback(data)
	-------------------------------------------
  if (data.ID == "UpdateNewMessage") then
    local msg = data.message_
    --vardump(data)
    local d = data.disable_notification_
    local chat = chats[msg.chat_id_]
	-------------------------------------------
	if msg.date_ < (os.time() - 30) then
       return false
    end
	-------------------------------------------
	if not database:get("bot:enable:"..msg.chat_id_) and not is_admin(msg.sender_user_id_, msg.chat_id_) then
      return false
    end
    -------------------------------------------
      if msg and msg.send_state_.ID == "MessageIsSuccessfullySent" then
	  --vardump(msg)
	   function get_mymsg_contact(extra, result, success)
             --vardump(result)
       end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,get_mymsg_contact)
         return false 
      end
    -------------* EXPIRE *-----------------
    if not database:get("bot:charge:"..msg.chat_id_) then
     if database:get("bot:enable:"..msg.chat_id_) then
      database:del("bot:enable:"..msg.chat_id_)
      for k,v in pairs(sudo_users) do
        send(v, 0, 1, "شارژ این گروه به اتمام رسید \nLink : "..(database:get("bot:group:link"..msg.chat_id_) or "تنظیم نشده").."\nID : "..msg.chat_id_..'\n\nدر صورتی که میخواهید ربات این گروه را ترک کند از دستور زیر استفاده کنید\n\n/leave'..msg.chat_id_..'\nبرای جوین دادن توی این گروه میتونی از دستور زیر استفاده کنی:\n/join'..msg.chat_id_..'\n_________________\nدر صورتی که میخواهید گروه رو دوباره شارژ کنید میتوانید از کد های زیر استفاده کنید...\n\n<code>برای شارژ 1 ماهه:</code>\n/plan1'..msg.chat_id_..'\n\n<code>برای شارژ 3 ماهه:</code>\n/plan2'..msg.chat_id_..'\n\n<code>برای شارژ نامحدود:</code>\n/plan3'..msg.chat_id_, 1, 'html')
      end
        send(msg.chat_id_, 0, 1, 'شارژ این گروه به اتمام رسید و ربات در گروه غیر فعال شد...\nبرای تمدید کردن ربات به @SudoMohammad پیام دهید.\nدر صورت ریپورت بودن میتوانید با ربات زیر با ما در ارتباط باشید:\n @PvSudoBot', 1, 'html')
        send(msg.chat_id_, 0, 1, 'ربات به دلایلی گروه را ترک میکند\nبرای اطلاعات بیشتر میتوانید با @SudoMohammad در ارتباط باشید.\nدر صورت ریپورت بودن میتوانید با ربات زیر به ما پیام دهید\n@PvSudoBot\n\nChannel> @VentTM', 1, 'html')
	   chat_leave(msg.chat_id_, bot_id)
      end
    end
    --------- ANTI FLOOD -------------------
	local hash = 'flood:max:'..msg.chat_id_
    if not database:get(hash) then
        floodMax = 5
    else
        floodMax = tonumber(database:get(hash))
    end

    local hash = 'flood:time:'..msg.chat_id_
    if not database:get(hash) then
        floodTime = 3
    else
        floodTime = tonumber(database:get(hash))
    end
    if not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local hashse = 'anti-flood:'..msg.chat_id_
        if not database:get(hashse) then
                if not is_mod(msg.sender_user_id_, msg.chat_id_) then
                    local hash = 'flood:'..msg.sender_user_id_..':'..msg.chat_id_..':msg-num'
                    local msgs = tonumber(database:get(hash) or 0)
                    if msgs > (floodMax - 1) then
                        local user = msg.sender_user_id_
                        local chat = msg.chat_id_
                        local channel = msg.chat_id_
						 local user_id = msg.sender_user_id_
						 local banned = is_banned(user_id, msg.chat_id_)
                         if banned then
						local id = msg.id_
        				local msgs = {[0] = id}
       					local chat = msg.chat_id_
       						       del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						    else
						 local id = msg.id_
                         local msgs = {[0] = id}
                         local chat = msg.chat_id_
		                chat_kick(msg.chat_id_, msg.sender_user_id_)
						 del_all_msgs(msg.chat_id_, msg.sender_user_id_)
						user_id = msg.sender_user_id_
						local bhash =  'bot:banned:'..msg.chat_id_
                        database:sadd(bhash, user_id)
                           send(msg.chat_id_, msg.id_, 1, '> _ID_  *('..msg.sender_user_id_..')* \n_Spamming Not Allowed Here._\n`Spammer Banned!!`', 1, 'md')
					  end
                    end
                    database:setex(hash, floodTime, msgs+1)
                end
        end
	end
	-------------------------------------------
	database:incr("bot:allmsgs")
	if msg.chat_id_ then
      local id = tostring(msg.chat_id_)
      if id:match('-100(%d+)') then
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
        elseif id:match('^(%d+)') then
        if not database:sismember("bot:userss",msg.chat_id_) then
            database:sadd("bot:userss",msg.chat_id_)
        end
        else
        if not database:sismember("bot:groups",msg.chat_id_) then
            database:sadd("bot:groups",msg.chat_id_)
        end
     end
    end
	-------------------------------------------
    -------------* MSG TYPES *-----------------
   if msg.content_ then
   	if msg.reply_markup_ and  msg.reply_markup_.ID == "ReplyMarkupInlineKeyboard" then
		print("Send INLINE KEYBOARD")
	msg_type = 'MSG:Inline'
	-------------------------
    elseif msg.content_.ID == "MessageText" then
	text = msg.content_.text_
		print("SEND TEXT")
	msg_type = 'MSG:Text'
	-------------------------
	elseif msg.content_.ID == "MessagePhoto" then
	print("SEND PHOTO")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Photo'
	-------------------------
	elseif msg.content_.ID == "MessageChatAddMembers" then
	print("NEW ADD TO GROUP")
	msg_type = 'MSG:NewUserAdd'
	-------------------------
	elseif msg.content_.ID == "MessageChatJoinByLink" then
		print("JOIN TO GROUP")
	msg_type = 'MSG:NewUserLink'
	-------------------------
	elseif msg.content_.ID == "MessageSticker" then
		print("SEND STICKER")
	msg_type = 'MSG:Sticker'
	-------------------------
	elseif msg.content_.ID == "MessageAudio" then
		print("SEND MUSIC")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Audio'
	-------------------------
	elseif msg.content_.ID == "MessageVoice" then
		print("SEND VOICE")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Voice'
	-------------------------
	elseif msg.content_.ID == "MessageVideo" then
		print("SEND VIDEO")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Video'
	-------------------------
	elseif msg.content_.ID == "MessageAnimation" then
		print("SEND GIF")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Gif'
	-------------------------
	elseif msg.content_.ID == "MessageLocation" then
		print("SEND LOCATION")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Location'
	-------------------------
	elseif msg.content_.ID == "MessageChatJoinByLink" or msg.content_.ID == "MessageChatAddMembers" then
	msg_type = 'MSG:NewUser'
	-------------------------
	elseif msg.content_.ID == "MessageContact" then
		print("SEND CONTACT")
	if msg.content_.caption_ then
	caption_text = msg.content_.caption_
	end
	msg_type = 'MSG:Contact'
	-------------------------
	end
   end
    -------------------------------------------
    -------------------------------------------
    if ((not d) and chat) then
      if msg.content_.ID == "MessageText" then
        do_notify (chat.title_, msg.content_.text_)
      else
        do_notify (chat.title_, msg.content_.ID)
      end
    end
  -----------------------------------------------------------------------------------------------
                                     -- end functions --
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------
                                     -- start code --
  -----------------------------------------------------------------------------------------------
  -------------------------------------- Process mod --------------------------------------------
  -----------------------------------------------------------------------------------------------
  
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  --------------------------******** START MSG CHECKS ********-------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
if is_banned(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		  return 
end
if is_muted(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
          delete_msg(chat,msgs)
		  return 
end
if is_gbanned(msg.sender_user_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
		  chat_kick(msg.chat_id_, msg.sender_user_id_)
		   return 
end	
if database:get('bot:muteall'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
        return 
end
    database:incr('user:msgs'..msg.chat_id_..':'..msg.sender_user_id_)
	database:incr('group:msgs'..msg.chat_id_)
if msg.content_.ID == "MessagePinMessage" then
  if database:get('pinnedmsg'..msg.chat_id_) and database:get('bot:pin:mute'..msg.chat_id_) then
   send(msg.chat_id_, msg.id_, 1, 'شما دسترسی به این کار را ندارید...\nمن پیام شما را آنپین و در صورت در دسترس بودن پیام قبل رو دوباره پین میکنم...\nدر صورتی که در ربات مقامی دارید میتوانید با ریپلی کردن پیام و ارسال دستور /pin پیام جدید رو برای پین شدن تنظیم کنید!', 1, 'md')
   unpinmsg(msg.chat_id_)
   local pin_id = database:get('pinnedmsg'..msg.chat_id_)
         pin(msg.chat_id_,pin_id,0)
   end
end
if database:get('bot:viewget'..msg.sender_user_id_) then 
    if not msg.forward_info_ then
		send(msg.chat_id_, msg.id_, 1, '*Error*\n`Please send this command again and forward your post(from channel)`', 1, 'md')
		database:del('bot:viewget'..msg.sender_user_id_)
	else
		send(msg.chat_id_, msg.id_, 1, 'Your Post Views:\n> '..msg.views_..' View!', 1, 'md')
        database:del('bot:viewget'..msg.sender_user_id_)
	end
end
if msg_type == 'MSG:Photo' then
   --vardump(msg)
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
     if database:get('bot:photo:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
  elseif msg_type == 'MSG:Inline' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    if database:get('bot:inline:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
  elseif msg_type == 'MSG:Sticker' then
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
  if database:get('bot:sticker:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
elseif msg_type == 'MSG:NewUserLink' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   function get_welcome(extra,result,success)
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*Hi {firstname} 😃*'
    end
    local text = text:gsub('{firstname}',(result.first_name_ or ''))
    local text = text:gsub('{lastname}',(result.last_name_ or ''))
    local text = text:gsub('{username}',(result.username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
	  if database:get("bot:welcome"..msg.chat_id_) then
        getUser(msg.sender_user_id_,get_welcome)
      end
elseif msg_type == 'MSG:NewUserAdd' then
  if database:get('bot:tgservice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
      --vardump(msg)
   if msg.content_.members_[0].username_ and msg.content_.members_[0].username_:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
	  end
   end
   if is_banned(msg.content_.members_[0].id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, msg.content_.members_[0].id_)
		 return false
   end
   if database:get("bot:welcome"..msg.chat_id_) then
    if database:get('welcome:'..msg.chat_id_) then
        text = database:get('welcome:'..msg.chat_id_)
    else
        text = '*Hi {firstname} 😃*'
    end
    local text = text:gsub('{firstname}',(msg.content_.members_[0].first_name_ or ''))
    local text = text:gsub('{lastname}',(msg.content_.members_[0].last_name_ or ''))
    local text = text:gsub('{username}',('@'..msg.content_.members_[0].username_ or ''))
         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
   end
elseif msg_type == 'MSG:Contact' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:contact:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   end
elseif msg_type == 'MSG:Audio' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:music:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return 
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
 if caption_text:match("@") or msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
  	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
     if caption_text:match("[\216-\219][\128-\191]") then
    if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Voice' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:voice:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
  if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
  if caption_text:match("@") then
  if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	 if caption_text:match("[\216-\219][\128-\191]") then
    if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Location' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:location:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Video' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:video:mute'..msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
      check_filter_words(msg, caption_text)
  if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   end
elseif msg_type == 'MSG:Gif' then
 if not is_mod(msg.sender_user_id_, msg.chat_id_) then
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
  if database:get('bot:gifs:mute'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
    local id = msg.id_
    local msgs = {[0] = id}
    local chat = msg.chat_id_
       delete_msg(chat,msgs)
          return  
   end
   if caption_text then
   check_filter_words(msg, caption_text)
   if caption_text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or caption_text:match("[Tt].[Mm][Ee]") or caption_text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("@") or msg.content_.entities_[0].ID and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("#") then
   if database:get('bot:hashtag:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if caption_text:match("[Hh][Tt][Tt][Pp][Ss]://") or caption_text:match("[Hh][Tt][Tt][Pp]://") or caption_text:match(".[Ii][Rr]") or caption_text:match(".[Cc][Oo][Mm]") or caption_text:match(".[Oo][Rr][Gg]") or caption_text:match(".[Ii][Nn][Ff][Oo]") or caption_text:match("[Ww][Ww][Ww].") or caption_text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if caption_text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   if caption_text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..msg.chat_id_) then
    local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end	
   end
elseif msg_type == 'MSG:Text' then
 --vardump(msg)
    if database:get("bot:group:link"..msg.chat_id_) == 'Waiting For Link!\nPls Send Group Link.\n\nJoin My Channel > @NotTeam' and is_mod(msg.sender_user_id_, msg.chat_id_) then if text:match("(https://telegram.me/joinchat/%S+)") then 	 local glink = text:match("(https://telegram.me/joinchat/%S+)") local hash = "bot:group:link"..msg.chat_id_ database:set(hash,glink) 			 send(msg.chat_id_, msg.id_, 1, '*New link Set!*', 1, 'md')
      end
   end
    function check_username(extra,result,success)
	 --vardump(result)
	local username = (result.username_ or '')
	local svuser = 'user:'..result.id_
	if username then
      database:hset(svuser, 'username', username)
    end
	if username and username:match("[Bb][Oo][Tt]$") then
      if database:get('bot:bots:mute'..msg.chat_id_) and not is_mod(result.id_, msg.chat_id_) then
		 chat_kick(msg.chat_id_, result.id_)
		 return false
		 end
	  end
   end
    getUser(msg.sender_user_id_,check_username)
   database:set('bot:editid'.. msg.id_,msg.content_.text_)
   if not is_mod(msg.sender_user_id_, msg.chat_id_) then
    check_filter_words(msg, text)
	if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or 
text:match("[Tt].[Mm][Ee]") or
text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
     if database:get('bot:links:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
	if text then
     if database:get('bot:text:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
if msg.forward_info_ then
if database:get('bot:forward:mute'..msg.chat_id_) then
	if msg.forward_info_.ID == "MessageForwardedFromUser" or msg.forward_info_.ID == "MessageForwardedPost" then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   end
   if text:match("@") or msg.content_.entities_[0] and msg.content_.entities_[0].ID == "MessageEntityMentionName" then
   if database:get('bot:tag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("#") then
      if database:get('bot:hashtag:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
      if database:get('bot:webpage:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	if text:match("[\216-\219][\128-\191]") then
      if database:get('bot:arabic:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	end
   end
   	  if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
      if database:get('bot:english:mute'..msg.chat_id_) then
     local id = msg.id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
        delete_msg(chat,msgs)
	  end
     end
    end
   end
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  ---------------------------******** END MSG CHECKS ********--------------------------------------------
  -------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------
  if database:get('bot:cmds'..msg.chat_id_) and not is_mod(msg.sender_user_id_, msg.chat_id_) then
  return 
  else
    ------------------------------------ With Pattern -------------------------------------------
	if text:match("^[#!/]ping$") then
	   send(msg.chat_id_, msg.id_, 1, '_Pong_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[!/#]leave$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	     chat_leave(msg.chat_id_, bot_id)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]promote$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function promote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already moderator._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _promoted as moderator._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,promote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]promote @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](promote) @(.*)$")} 
	function promote_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:mods:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>promoted as moderator.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],promote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]promote (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](promote) (%d+)$")} 	
	        database:sadd('bot:mods:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _promoted as moderator._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demote$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function demote_by_reply(extra, result, success)
	local hash = 'bot:mods:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Promoted._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Demoted._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,demote_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demote @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!](demote) @(.*)$")} 
	function demote_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Demoted</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],demote_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demote (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:mods:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!](demote) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Demoted._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]ban$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function ban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Banned._', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Banned._', 1, 'md')
		 chat_kick(result.chat_id_, result.sender_user_id_)
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]ban @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](ban) @(.*)$")} 
	function ban_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Banned.!</b>'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],ban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]ban (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](ban) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:banned:'..msg.chat_id_, ap[2])
		 chat_kick(msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Banned._', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]delall$") and is_owner(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function delall_by_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t Delete Msgs from Moderators!!*', 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, '_All Msgs from _ *'..result.sender_user_id_..'* _Has been deleted!!_', 1, 'md')
		     del_all_msgs(result.chat_id_, result.sender_user_id_)
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,delall_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]delall (%d+)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
		local ass = {string.match(text, "^[#/!](delall) (%d+)$")} 
	if is_mod(ass[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t Delete Msgs from Moderators!!*', 1, 'md')
    else
	 		     del_all_msgs(msg.chat_id_, ass[2])
         send(msg.chat_id_, msg.id_, 1, '<b>All Msg From user</b> <code>'..ass[2]..'</code> <b>Deleted!</b>', 1, 'html')
    end
	end
 -----------------------------------------------------------------------------------------------
	if text:match("^[#!/]delall @(.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](delall) @(.*)$")} 
	function delall_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t Delete Msgs from Moderators!!*', 1, 'md')
		 return false
    end
		 		     del_all_msgs(msg.chat_id_, result.id_)
            text = '<b>All Msg From user</b> <code>'..result.id_..'</code> <b>Deleted!</b>'
            else 
            text = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],delall_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]unban$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unban_by_reply(extra, result, success)
	local hash = 'bot:banned:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Banned._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Unbanned._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]unban @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](unban) @(.*)$")} 
	function unban_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:banned:'..msg.chat_id_, result.id_)
            text = '<b>User </b><code>'..result.id_..'</code> <b>Unbanned.!</b>'
            else 
            text = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unban_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]unban (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](unban) (%d+)$")} 	
	        database:srem('bot:banned:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Unbanned._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]muteuser$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function mute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Mute] Moderators!!*', 1, 'md')
    else
    if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Muted._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Muted._', 1, 'md')
	end
    end
	end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,mute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]muteuser @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](muteuser) @(.*)$")} 
	function mute_by_username(extra, result, success)
	if result.id_ then
	if is_mod(result.id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Mute] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Muted.!</b>'
		 chat_kick(msg.chat_id_, result.id_)
	end
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],mute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]muteuser (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](muteuser) (%d+)$")}
	if is_mod(ap[2], msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Mute] Moderators!!*', 1, 'md')
    else
	        database:sadd('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Muted._', 1, 'md')
	end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]unmuteuser$") and is_mod(msg.sender_user_id_, msg.chat_id_) and msg.reply_to_message_id_ then
	function unmute_by_reply(extra, result, success)
	local hash = 'bot:muted:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Muted._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Unmuted._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,unmute_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]unmuteuser @(.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](unmuteuser) @(.*)$")} 
	function unmute_by_username(extra, result, success)
	if result.id_ then
         database:srem('bot:muted:'..msg.chat_id_, result.id_)
            text = '<b>User </b><code>'..result.id_..'</code> <b>Unmuted.!</b>'
            else 
            text = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	      resolve_username(ap[2],unmute_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]unmuteuser (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](unmuteuser) (%d+)$")} 	
	        database:srem('bot:muted:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Unmuted._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setowner$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function setowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Owner._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Promoted as Group Owner._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,setowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setowner @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](setowner) @(.*)$")} 
	function setowner_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:owners:'..msg.chat_id_, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Promoted as Group Owner.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],setowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setowner (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local ap = {string.match(text, "^[#/!](setowner) (%d+)$")} 	
	        database:sadd('bot:owners:'..msg.chat_id_, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Promoted as Group Owner._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demowner$") and is_admin(msg.sender_user_id_) and msg.reply_to_message_id_ then
	function deowner_by_reply(extra, result, success)
	local hash = 'bot:owners:'..msg.chat_id_
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Owner._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Removed from ownerlist._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deowner_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demowner @(.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!](demowner) @(.*)$")} 
	function remowner_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Removed from ownerlist</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remowner_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]demowner (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:owners:'..msg.chat_id_
	local ap = {string.match(text, "^[#/!](demowner) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Removed from ownerlist._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]addadmin$") and is_sudo(msg) and msg.reply_to_message_id_ then
	function addadmin_by_reply(extra, result, success)
	local hash = 'bot:admins:'
	if database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is Already Admin._', 1, 'md')
	else
         database:sadd(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Added to MeGaNot admins._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,addadmin_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]addadmin @(.*)$") and is_sudo(msg) then
	local ap = {string.match(text, "^[#/!](addadmin) @(.*)$")} 
	function addadmin_by_username(extra, result, success)
	if result.id_ then
	        database:sadd('bot:admins:', result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Added to MeGaNot admins.!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],addadmin_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]addadmin (%d+)$") and is_sudo(msg) then
	local ap = {string.match(text, "^[#/!](addadmin) (%d+)$")} 	
	        database:sadd('bot:admins:', ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* _Added to MeGaNot admins._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]remadmin$") and is_sudo(msg) and msg.reply_to_message_id_ then
	function deadmin_by_reply(extra, result, success)
	local hash = 'bot:admins:'
	if not database:sismember(hash, result.sender_user_id_) then
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _is not Admin._', 1, 'md')
	else
         database:srem(hash, result.sender_user_id_)
         send(msg.chat_id_, msg.id_, 1, '_User_ *'..result.sender_user_id_..'* _Removed from MeGaNot Admins!._', 1, 'md')
	end
    end
	      getMessage(msg.chat_id_, msg.reply_to_message_id_,deadmin_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]remadmin @(.*)$") and is_sudo(msg) then
	local hash = 'bot:admins:'
	local ap = {string.match(text, "^[#/!](remadmin) @(.*)$")} 
	function remadmin_by_username(extra, result, success)
	if result.id_ then
         database:srem(hash, result.id_)
            texts = '<b>User </b><code>'..result.id_..'</code> <b>Removed from MeGaNot Admins!</b>'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'html')
    end
	      resolve_username(ap[2],remadmin_by_username)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]remadmin (%d+)$") and is_sudo(msg) then
	local hash = 'bot:admins:'
	local ap = {string.match(text, "^[#/!](remadmin) (%d+)$")} 	
         database:srem(hash, ap[2])
	send(msg.chat_id_, msg.id_, 1, '_User_ *'..ap[2]..'* Removed from MeGaNot Admins!_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]modlist$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:mods:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Mod List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "Mod List is empty"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]mutelist$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:muted:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Mute List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "MuteList is empty"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]owner$") or text:match("^[#!/]ownerlist$") and is_sudo(msg) then
    local hash =  'bot:owners:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Owner List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "Owner List is empty"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]banlist$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local hash =  'bot:banned:'..msg.chat_id_
	local list = database:smembers(hash)
	local text = "<b>Ban List:</b>\n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "Ban List is empty"
    end
	send(msg.chat_id_, msg.id_, 1, text, 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]adminlist$") and is_sudo(msg) then
    local hash =  'bot:admins:'
	local list = database:smembers(hash)
	local text = "Bot Admins : \n\n"
	for k,v in pairs(list) do
	local user_info = database:hgetall('user:'..v)
		if user_info and user_info.username then
			local username = user_info.username
			text = text..k.." - @"..username.." ["..v.."]\n"
		else
			text = text..k.." - "..v.."\n"
		end
	end
	if #list == 0 then
       text = "Bot Admins List is empty"
    end
    send(msg.chat_id_, msg.id_, 1, '`'..text..'`', 'md')
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/]id$") and msg.reply_to_message_id_ ~= 0 then
      function id_by_reply(extra, result, success)
	  local user_msgs = database:get('user:msgs'..result.chat_id_..':'..result.sender_user_id_)
        send(msg.chat_id_, msg.id_, 1, "*User ID:* `"..result.sender_user_id_.."`", 1, 'md')
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,id_by_reply)
  end
  -----------------------------------------------------------------------------------------------
    if text:match("^[#!/]id @(.*)$") then
	local ap = {string.match(text, "^[#/!](id) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
	if is_sudo(result) then
	  t = 'Sudo'
      elseif is_admin(result.id_) then
	  t = 'Global Admin'
      elseif is_owner(result.id_, msg.chat_id_) then
	  t = 'Group Owner'
      elseif is_mod(result.id_, msg.chat_id_) then
	  t = 'Moderator'
      else
	  t = 'Member'
	  end
            texts = '*Username* : `@'..ap[2]..'`\n*ID* : `('..result.id_..')`\n*> Rank* : `'..t..'`'
            else 
            texts = '<code>User not found!</code>'
    end
	         send(msg.chat_id_, msg.id_, 1, texts, 1, 'md')
    end
	      resolve_username(ap[2],id_by_username)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]kick$") and msg.reply_to_message_id_ and is_mod(msg.sender_user_id_, msg.chat_id_) then
      function kick_reply(extra, result, success)
	if is_mod(result.sender_user_id_, result.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*You Can,t [Kick/Ban] Moderators!!*', 1, 'md')
    else
        send(msg.chat_id_, msg.id_, 1, 'User '..result.sender_user_id_..' Kicked.', 1, 'html')
        chat_kick(result.chat_id_, result.sender_user_id_)
        end
	end
   getMessage(msg.chat_id_,msg.reply_to_message_id_,kick_reply)
    end
    -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]inv$") and msg.reply_to_message_id_ and is_sudo(msg) then
      function inv_reply(extra, result, success)
           add_user(result.chat_id_, result.sender_user_id_, 5)
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,inv_reply)
    end
	-----------------------------------------------------------------------------------------------
    if text:match("^[#!/]getpro (%d+)$") and msg.reply_to_message_id_ == 0  then
		local pronumb = {string.match(text, "^[#/!](getpro) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[2] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 2 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 3 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 4 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 5 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '6' then
   if result.photos_[5] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[5].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 6 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 7 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 8 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "You Have'nt 9 Profile Photo!!", 1, 'md')
   end
   elseif pronumb[2] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_)
   else
      send(msg.chat_id_, msg.id_, 1, "_You Have'nt 10 Profile Photo!!_", 1, 'md')
   end
   else
      send(msg.chat_id_, msg.id_, 1, "*I just can get last 10 profile photos!:(*", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = pronumb[2]
  }, gpro, nil)
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]lock (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^[#/!](lock) (.*)$")} 
      if lockpt[2] == "edit" then
         send(msg.chat_id_, msg.id_, 1, '*Done*\n_Msg Edit locked for normal members._', 1, 'md')
         database:set('editmsg'..msg.chat_id_,'delmsg')
	  end
	  if lockpt[2] == "cmds" then
         send(msg.chat_id_, msg.id_, 1, '_> Bot Commands Has Been Locked_\n*[Now All Members Can`t Use Normal Commands.]*', 1, 'md')
         database:set('bot:cmds'..msg.chat_id_,true)
      end
	  if lockpt[2] == "bots" then
         send(msg.chat_id_, msg.id_, 1, '_> Bots Has been_ *Locked*', 1, 'md')
         database:set('bot:bots:mute'..msg.chat_id_,true)
      end
	  if lockpt[2] == "flood" then
         send(msg.chat_id_, msg.id_, 1, '*Flood* has been *locked*', 1, 'md')
         database:del('anti-flood:'..msg.chat_id_)
	  end
	  if lockpt[2] == "pin" then
         send(msg.chat_id_, msg.id_, 1, "*Now Members can't pin a msg*", 1, 'md')
	     database:set('bot:pin:mute'..msg.chat_id_,true)
      end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setflood (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodmax = {string.match(text, "^[#/!](setflood) (%d+)$")} 
	if tonumber(floodmax[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [2-99999]_', 1, 'md')
	else
    database:set('flood:max:'..msg.chat_id_,floodmax[2])
         send(msg.chat_id_, msg.id_, 1, '_> Flood has been set to_ *'..floodmax[2]..'*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setfloodtime (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local floodt = {string.match(text, "^[#/!](setfloodtime) (%d+)$")} 
	if tonumber(floodt[2]) < 2 then
         send(msg.chat_id_, msg.id_, 1, '*Wrong number*,_range is  [2-99999]_', 1, 'md')
	else
    database:set('flood:time:'..msg.chat_id_,floodt[2])
         send(msg.chat_id_, msg.id_, 1, '_> Flood has been set to_ *'..floodt[2]..'*', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]show edit$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Done*', 1, 'md')
         database:set('editmsg'..msg.chat_id_,'didam')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setlink$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Please Send Group Link Now!*', 1, 'md')
         database:set("bot:group:link"..msg.chat_id_, 'Waiting For Link!\nPls Send Group Link.\n\nJoin My Channel > @Black_Ch')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]link$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local link = database:get("bot:group:link"..msg.chat_id_)
	  if link then
         send(msg.chat_id_, msg.id_, 1, '<b>Group link:</b>\n'..link, 1, 'html')
	  else
         send(msg.chat_id_, msg.id_, 1, '*There is not link set yet. Please add one by #setlink .*', 1, 'md')
	  end
 	end
	
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]welcome on$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '#Done\nWelcome *Enabled* In This Supergroup.', 1, 'md')
		 database:set("bot:welcome"..msg.chat_id_,true)
	end
	if text:match("^[#!/]welcome off$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '#Done\nWelcome *Disabled* In This Supergroup.', 1, 'md')
		 database:del("bot:welcome"..msg.chat_id_)
	end
	if text:match("^[#!/]set welcome (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local welcome = {string.match(text, "^[#/!](set welcome) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, '*Welcome Msg Has Been Saved!*\nWlc Text:\n\n`'..welcome[2]..'`', 1, 'md')
		 database:set('welcome:'..msg.chat_id_,welcome[2])
	end
	if text:match("^[#!/]del welcome$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '*Welcome Msg Has Been Deleted!*', 1, 'md')
		 database:del('welcome:'..msg.chat_id_)
	end
	if text:match("^[#!/]get welcome$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local wel = database:get('welcome:'..msg.chat_id_)
	if wel then
         send(msg.chat_id_, msg.id_, 1, wel, 1, 'md')
    else
         send(msg.chat_id_, msg.id_, 1, 'Welcome msg not saved!', 1, 'md')
	end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]action (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local lockpt = {string.match(text, "^[#/!](action) (.*)$")} 
      if lockpt[2] == "typing" then
          sendaction(msg.chat_id_, 'Typing')
	  end
	  if lockpt[2] == "video" then
          sendaction(msg.chat_id_, 'RecordVideo')
	  end
	  if lockpt[2] == "voice" then
          sendaction(msg.chat_id_, 'RecordVoice')
	  end
	  if lockpt[2] == "photo" then
          sendaction(msg.chat_id_, 'UploadPhoto')
	  end
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]filter (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local filters = {string.match(text, "^[#/!](filter) (.*)$")} 
    local name = string.sub(filters[2], 1, 50)
          database:hset('bot:filters:'..msg.chat_id_, name, 'filtered')
		  send(msg.chat_id_, msg.id_, 1, "*New Word Filtered!*\n--> `"..name.."`", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]rw (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local rws = {string.match(text, "^[#/!](rw) (.*)$")} 
    local name = string.sub(rws[2], 1, 50)
          database:hdel('bot:filters:'..msg.chat_id_, rws[2])
		  send(msg.chat_id_, msg.id_, 1, "`"..rws[2].."` *Removed From Filtered List!*", 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]filterlist$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local hash = 'bot:filters:'..msg.chat_id_
      if hash then
         local names = database:hkeys(hash)
         local text = '*Filtered Words :*\n\n'
    for i=1, #names do
      text = text..'> `'..names[i]..'`\n'
    end
	if #names == 0 then
       text = "*Filter List is empty*"
    end
		  send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]bc (.*)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups") or 0
    local gpss = database:smembers("bot:groups") or 0
	local rws = {string.match(text, "^[#/!](bc) (.*)$")} 
	for i=1, #gpss do
		  send(gpss[i], 0, 1, rws[2], 1, 'md')
    end
                   send(msg.chat_id_, msg.id_, 1, '*Done*\n_Your Msg Send to_ `'..gps..'` _Groups_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]stats$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
    local gps = database:scard("bot:groups")
	local users = database:scard("bot:userss")
    local allmgs = database:get("bot:allmsgs")
                   send(msg.chat_id_, msg.id_, 1, '*Groups :* `'..gps..'`', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]unlock (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unlockpt = {string.match(text, "^[#/!](unlock) (.*)$")} 
      if unlockpt[2] == "edit" then
         send(msg.chat_id_, msg.id_, 1, '*Done*\n_Msg Edit has been unlocked._', 1, 'md')
         database:del('editmsg'..msg.chat_id_)
      end
	  if unlockpt[2] == "cmds" then
         send(msg.chat_id_, msg.id_, 1, '_> Bot Commands Has Been Unlocked_\n*[Now All Members Can Use Normal Commands.]*', 1, 'md')
         database:del('bot:cmds'..msg.chat_id_)
      end
	  if unlockpt[2] == "bots" then
         send(msg.chat_id_, msg.id_, 1, '_> Bots Has been_ *Unlocked*', 1, 'md')
         database:del('bot:bots:mute'..msg.chat_id_)
      end
	  if unlockpt[2] == "flood" then
         send(msg.chat_id_, msg.id_, 1, '*Flood* has been *unlocked*', 1, 'md')
         database:set('anti-flood:'..msg.chat_id_,true)
	  end
	  if unlockpt[2] == "pin" then
         send(msg.chat_id_, msg.id_, 1, "*Now Members can pin a msg*", 1, 'md')
	     database:del('bot:pin:mute'..msg.chat_id_)
      end
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]mute all (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^[#!/]mute all (%d+)$")}
	    		database:setex('bot:muteall'..msg.chat_id_, tonumber(mutept[1]), true)
         send(msg.chat_id_, msg.id_, 1, '_> Group muted for_ *'..mutept[1]..'* _seconds!_', 1, 'md')
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]mute (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local mutept = {string.match(text, "^[#/!](mute) (.*)$")} 
      if mutept[2] == "all" then
         send(msg.chat_id_, msg.id_, 1, '_Mute All has been_ *enabled*', 1, 'md')
         database:set('bot:muteall'..msg.chat_id_,true)
      end
	  if mutept[2] == "text" then
         send(msg.chat_id_, msg.id_, 1, '_> Text Has been_ *Muted*', 1, 'md')
         database:set('bot:text:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "inline" then
         send(msg.chat_id_, msg.id_, 1, '_> Inline Has been_ *Muted*', 1, 'md')
         database:set('bot:inline:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "photo" then
         send(msg.chat_id_, msg.id_, 1, '_> Photo Has been_ *Muted*', 1, 'md')
         database:set('bot:photo:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "video" then
         send(msg.chat_id_, msg.id_, 1, '_> Video Has been_ *Muted*', 1, 'md')
         database:set('bot:video:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "gifs" then
         send(msg.chat_id_, msg.id_, 1, '_> Gifs Has been_ *Muted*', 1, 'md')
         database:set('bot:gifs:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "music" then
         send(msg.chat_id_, msg.id_, 1, '_> Music Has been_ *Muted*', 1, 'md')
         database:set('bot:music:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "voice" then
         send(msg.chat_id_, msg.id_, 1, '_> Voice Has been_ *Muted*', 1, 'md')
         database:set('bot:voice:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "links" then
         send(msg.chat_id_, msg.id_, 1, '> *Link* posting has been *Locked*', 1, 'md')
         database:set('bot:links:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "location" then
         send(msg.chat_id_, msg.id_, 1, '> *location* posting has been *Locked*', 1, 'md')
         database:set('bot:location:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "tag" then
         send(msg.chat_id_, msg.id_, 1, '> *Tag/Mention* posting has been *Locked*', 1, 'md')
         database:set('bot:tag:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "hashtag" then
         send(msg.chat_id_, msg.id_, 1, '> *Hashtag* posting has been *Locked*', 1, 'md')
         database:set('bot:hashtag:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "contact" then
         send(msg.chat_id_, msg.id_, 1, '> *Contact* posting has been *Locked*', 1, 'md')
         database:set('bot:contact:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "webpage" then
         send(msg.chat_id_, msg.id_, 1, '> *Hashtag* posting has been *Locked*', 1, 'md')
         database:set('bot:webpage:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "arabic" then
         send(msg.chat_id_, msg.id_, 1, '> *Arabic/Persian* has been *Locked*', 1, 'md')
         database:set('bot:arabic:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "english" then
         send(msg.chat_id_, msg.id_, 1, '> *English* has been *Locked*', 1, 'md')
         database:set('bot:english:mute'..msg.chat_id_,true)
      end 
	  if mutept[2] == "sticker" then
         send(msg.chat_id_, msg.id_, 1, '> *Sticker* posting has been *Locked*', 1, 'md')
         database:set('bot:sticker:mute'..msg.chat_id_,true)
      end 
	  if mutept[2] == "service" then
         send(msg.chat_id_, msg.id_, 1, '> *Joining Msgs* has been *Locked*', 1, 'md')
         database:set('bot:tgservice:mute'..msg.chat_id_,true)
      end
	  if mutept[2] == "forward" then
         send(msg.chat_id_, msg.id_, 1, '> *Forward* has been *Locked*', 1, 'md')
         database:set('bot:forward:mute'..msg.chat_id_,true)
      end
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]unmute (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local unmutept = {string.match(text, "^[#/!](unmute) (.*)$")} 
      if unmutept[2] == "all" then
         send(msg.chat_id_, msg.id_, 1, '_Mute All has been_ *Disabled*', 1, 'md')
         database:del('bot:muteall'..msg.chat_id_)
      end
	  if unmutept[2] == "text" then
         send(msg.chat_id_, msg.id_, 1, '_> Text Has been_ *Unmuted*', 1, 'md')
         database:del('bot:text:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "photo" then
         send(msg.chat_id_, msg.id_, 1, '_> Photo Has been_ *Unmuted*', 1, 'md')
         database:del('bot:photo:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "video" then
         send(msg.chat_id_, msg.id_, 1, '_> Video Has been_ *Unmuted*', 1, 'md')
         database:del('bot:video:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "inline" then
         send(msg.chat_id_, msg.id_, 1, '_> inline Has been_ *Unmuted*', 1, 'md')
         database:del('bot:inline:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "gifs" then
         send(msg.chat_id_, msg.id_, 1, '_> Gifs Has been_ *Unmuted*', 1, 'md')
         database:del('bot:gifs:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "music" then
         send(msg.chat_id_, msg.id_, 1, '_> Music Has been_ *Unmuted*', 1, 'md')
         database:del('bot:music:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "voice" then
         send(msg.chat_id_, msg.id_, 1, '_> Voice Has been_ *Unmuted*', 1, 'md')
         database:del('bot:voice:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "links" then
         send(msg.chat_id_, msg.id_, 1, '> *Link* posting has been *Unlocked*', 1, 'md')
         database:del('bot:links:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "location" then
         send(msg.chat_id_, msg.id_, 1, '> *location* posting has been *Unlocked*', 1, 'md')
         database:del('bot:location:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "tag" then
         send(msg.chat_id_, msg.id_, 1, '> *Tag/Mention* posting has been *Unlocked*', 1, 'md')
         database:del('bot:tag:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "hashtag" then
         send(msg.chat_id_, msg.id_, 1, '> *Hashtag* posting has been *Unlocked*', 1, 'md')
         database:del('bot:hashtag:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "contact" then
         send(msg.chat_id_, msg.id_, 1, '> *Contact* posting has been *Unlocked*', 1, 'md')
         database:del('bot:contact:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "webpage" then
         send(msg.chat_id_, msg.id_, 1, '> *Hashtag* posting has been *Unlocked*', 1, 'md')
         database:del('bot:webpage:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "arabic" then
         send(msg.chat_id_, msg.id_, 1, '> *Arabic/Persian* has been *Unlocked*', 1, 'md')
         database:del('bot:arabic:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "english" then
         send(msg.chat_id_, msg.id_, 1, '> *English* has been *Unlocked*', 1, 'md')
         database:del('bot:english:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "service" then
         send(msg.chat_id_, msg.id_, 1, '> *Joining Msgs* has been *Unlocked*', 1, 'md')
         database:del('bot:tgservice:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "sticker" then
         send(msg.chat_id_, msg.id_, 1, '> *Sticker* posting has been *Unlocked*', 1, 'md')
         database:del('bot:sticker:mute'..msg.chat_id_)
      end
	  if unmutept[2] == "forward" then
         send(msg.chat_id_, msg.id_, 1, '> *Forward* has been *Unlocked*', 1, 'md')
         database:del('bot:forward:mute'..msg.chat_id_)
      end 
	end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]edit (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local editmsg = {string.match(text, "^[#/!](edit) (.*)$")} 
		 edit(msg.chat_id_, msg.reply_to_message_id_, nil, editmsg[2], 1, 'html')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]user$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	          send(msg.chat_id_, msg.id_, 1, '*'..from_username(msg)..'*', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]clean (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](clean) (.*)$")} 
       if txt[2] == 'banlist' then
	      database:del('bot:banned:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> Banlist has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'bots' then
	  local function g_bots(extra,result,success)
      local bots = result.members_
      for i=0 , #bots do
          chat_kick(msg.chat_id_,bots[i].user_id_)
          end
      end
    channel_get_bots(msg.chat_id_,g_bots)
	          send(msg.chat_id_, msg.id_, 1, '_> All bots_ *kicked!*', 1, 'md')
	end
	   if txt[2] == 'modlist' then
	      database:del('bot:mods:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> Modlist has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'filterlist' then
	      database:del('bot:filters:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> Filterlist has been_ *Cleaned*', 1, 'md')
       end
	   if txt[2] == 'mutelist' then
	      database:del('bot:muted:'..msg.chat_id_)
          send(msg.chat_id_, msg.id_, 1, '_> Mutelist has been_ *Cleaned*', 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
  	 if text:match("^[#!/]settings$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	if database:get('bot:muteall'..msg.chat_id_) then
	mute_all = '`[قفل | 🔐]`'
	else
	mute_all = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:text:mute'..msg.chat_id_) then
	mute_text = '`[قفل | 🔐]`'
	else
	mute_text = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:photo:mute'..msg.chat_id_) then
	mute_photo = '`[قفل | 🔐]`'
	else
	mute_photo = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:video:mute'..msg.chat_id_) then
	mute_video = '`[قفل | 🔐]`'
	else
	mute_video = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:gifs:mute'..msg.chat_id_) then
	mute_gifs = '`[قفل | 🔐]`'
	else
	mute_gifs = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('anti-flood:'..msg.chat_id_) then
	mute_flood = '`[آزاد | 🔓]`'
	else
	mute_flood = '`[قفل | 🔐]`'
	end
	------------
	if not database:get('flood:max:'..msg.chat_id_) then
	flood_m = 5
	else
	flood_m = database:get('flood:max:'..msg.chat_id_)
	end
	------------
	if not database:get('flood:time:'..msg.chat_id_) then
	flood_t = 3
	else
	flood_t = database:get('flood:time:'..msg.chat_id_)
	end
	------------
	if database:get('bot:music:mute'..msg.chat_id_) then
	mute_music = '`[قفل | 🔐]`'
	else
	mute_music = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:bots:mute'..msg.chat_id_) then
	mute_bots = '`[قفل | 🔐]`'
	else
	mute_bots = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:inline:mute'..msg.chat_id_) then
	mute_in = '`[قفل | 🔐]`'
	else
	mute_in = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('bot:cmds'..msg.chat_id_) then
	mute_cmd = '[غیر فعال|⭕]'
	else
	mute_cmd = '[فعال|✔]'
	end
	------------
	if database:get('bot:voice:mute'..msg.chat_id_) then
	mute_voice = '`[قفل | 🔐]`'
	else
	mute_voice = '`[آزاد | 🔓]`'
	end
	------------
	if database:get('editmsg'..msg.chat_id_) then
	mute_edit = '`[قفل | 🔐]`'
	else
	mute_edit = '`[آزاد | 🔓]`'
	end
    ------------
	if database:get('bot:links:mute'..msg.chat_id_) then
	mute_links = '`[قفل | 🔐]`'
	else
	mute_links = '`[آزاد | 🔓]`'
	end
    ------------
	if database:get('bot:pin:mute'..msg.chat_id_) then
	lock_pin = '`[قفل | 🔐]`'
	else
	lock_pin = '`[آزاد | 🔓]`'
	end 
    ------------
	if database:get('bot:sticker:mute'..msg.chat_id_) then
	lock_sticker = '`[قفل | 🔐]`'
	else
	lock_sticker = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:tgservice:mute'..msg.chat_id_) then
	lock_tgservice = '`[قفل | 🔐]`'
	else
	lock_tgservice = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:webpage:mute'..msg.chat_id_) then
	lock_wp = '`[قفل | 🔐]`'
	else
	lock_wp = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:hashtag:mute'..msg.chat_id_) then
	lock_htag = '`[قفل | 🔐]`'
	else
	lock_htag = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:tag:mute'..msg.chat_id_) then
	lock_tag = '`[قفل | 🔐]`'
	else
	lock_tag = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:location:mute'..msg.chat_id_) then
	lock_location = '`[قفل | 🔐]`'
	else
	lock_location = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:contact:mute'..msg.chat_id_) then
	lock_contact = '`[قفل | 🔐]`'
	else
	lock_contact = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:english:mute'..msg.chat_id_) then
	lock_english = '`[قفل | 🔐]`'
	else
	lock_english = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:arabic:mute'..msg.chat_id_) then
	lock_arabic = '`[قفل | 🔐]`'
	else
	lock_arabic = '`[آزاد | 🔓]`'
	end
	------------
    if database:get('bot:forward:mute'..msg.chat_id_) then
	lock_forward = '`[قفل | 🔐]`'
	else
	lock_forward = '`[آزاد | 🔓]`'
	end
	------------
	if database:get("bot:welcome"..msg.chat_id_) then
	send_welcome = '[فعال|✔]'
	else
	send_welcome = '[غیر فعال|⭕]'
	end
	------------
	local ex = database:ttl("bot:charge:"..msg.chat_id_)
                if ex == -1 then
				exp_dat = 'نامحدود'
				else
				exp_dat = math.floor(ex / 86400) + 1
			    end
 	------------
	 local TXT = "============\n*﴿تنظیمات گروه﴾*\n============\n*قفل لینک* : "..mute_links.."\n" .."*قفل ادیت* : "..mute_edit.."\n" .."*قفل ربات* : "..mute_bots.."\n" .."*قفل فلود* : "..mute_flood.."\n" .."*قفل کیبورد انلاین* : "..mute_in.."\n" .."*قفل انگلیسی* : "..lock_english.."\n" .."*قفل فروارد* : "..lock_forward.."\n" .."*قفل پین پیام* : "..lock_pin.."\n" .."*قفل عربی* : "..lock_arabic.."\n" .."*قفل هشتنگ* : "..lock_htag.."\n".."*قفل یوزرنیم* : "..lock_tag.."\n" .."*قفل آرتی ال* : "..lock_wp.."\n" .."*قفل مکان* : "..lock_location.."\n" .."*قفل تگ سرویس* : "..lock_tgservice.."\n"
.."============\n*﴿لیست میوت ها﴾*\n============\n*میوت عکس* : "..mute_photo.."\n" .."*میوت متن* : "..mute_text.."\n" .."*میوت گیف* : "..mute_gifs.."\n" .."*میوت وییس* : "..mute_voice.."\n" .."*میوت اهنگ* : "..mute_music.."\n" .."*میوت ویدیو* : "..mute_video.."\n"
.."============\n *﴿دیگر تنظیمات﴾ *\n============\n*قفل دستور های ربات* : "..mute_cmd.."\n".."*پیام خوش امد* : "..send_welcome.."\n*تایم فلود*  "..flood_t.."\n" .."*تعداد فلود* : "..flood_m.."\n"
.."*تاریخ انقضا* : "..exp_dat.."\n" .."*چنل* : @NotTeam"
         send(msg.chat_id_, msg.id_, 1, TXT, 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]echo (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](echo) (.*)$")} 
         send(msg.chat_id_, msg.id_, 1, txt[2], 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]setrules (.*)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](setrules) (.*)$")}
	database:set('bot:rules'..msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '_Group rules upadted..._', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]rules$") then
	local rules = database:get('bot:rules'..msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, rules, 1, nil)
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]sh$") and is_sudo(msg) then
       sendContact(msg.chat_id_, msg.id_, 0, 1, nil, 79066978730, 'MeGaNot', '(Test Version..!)', bot_id)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setname (.*)$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](setname) (.*)$")} 
	     changetitle(msg.chat_id_, txt[2])
         send(msg.chat_id_, msg.id_, 1, '_Group name updated!_', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]getme$") then
	function guser_by_reply(extra, result, success)
         --vardump(result)
    end
	     getUser(msg.sender_user_id_,guser_by_reply)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]setphoto$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         send(msg.chat_id_, msg.id_, 1, '_Please send a photo noew!_', 1, 'md')
		 database:set('bot:setphoto'..msg.chat_id_..':'..msg.sender_user_id_,true)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]charge (%d+)$") and is_admin(msg.sender_user_id_, msg.chat_id_) then
		local a = {string.match(text, "^[#/!](charge) (%d+)$")} 
         send(msg.chat_id_, msg.id_, 1, '_Group Charged for_ *'..a[2]..'* _Days_', 1, 'md')
		 local time = a[2] * day
         database:setex("bot:charge:"..msg.chat_id_,time,true)
		 database:set("bot:enable:"..msg.chat_id_,true)
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]stats charge") and is_mod(msg.sender_user_id_, msg.chat_id_) then
    local ex = database:ttl("bot:charge:"..msg.chat_id_)
       if ex == -1 then
		send(msg.chat_id_, msg.id_, 1, '_نامحدود!_', 1, 'md')
       else
        local d = math.floor(ex / day ) + 1
	   		send(msg.chat_id_, msg.id_, 1, d.." روز تا انقضا گروه باقی مانده", 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]charge stats (%d+)") and is_admin(msg.sender_user_id_, msg.chat_id_) then
	local txt = {string.match(text, "^[#/!](charge stats) (%d+)$")} 
    local ex = database:ttl("bot:charge:"..txt[2])
       if ex == -1 then
		send(msg.chat_id_, msg.id_, 1, '_نامحدود!_', 1, 'md')
       else
        local d = math.floor(ex / day ) + 1
	   		send(msg.chat_id_, msg.id_, 1, d.." روز تا انقضا گروه باقی مانده", 1, 'md')
       end
    end
	-----------------------------------------------------------------------------------------------
	 if is_sudo(msg) then
  -----------------------------------------------------------------------------------------------
  if text:match("^[#!/]leave(-%d+)") and is_admin(msg.sender_user_id_, msg.chat_id_) then
  	local txt = {string.match(text, "^[#/!](leave)(-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, 'ربات با موفقیت از گروه '..txt[2]..' خارج شد.', 1, 'md')
	   send(txt[2], 0, 1, 'ربات به دلایلی گروه را ترک میکند\nبرای اطلاعات بیشتر میتوانید با @Loper_lua در ارتباط باشید.\nدر صورت ریپورت بودن میتوانید با ربات زیر به ما پیام دهید\n@mohi_ReBot\n\nChannel> @NotTeam', 1, 'html')
	   chat_leave(txt[2], bot_id)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]plan1(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](plan1)(-%d+)$")} 
       local timeplan1 = 2592000
       database:setex("bot:charge:"..txt[2],timeplan1,true)
	   send(msg.chat_id_, msg.id_, 1, 'پلن 1 با موفقیت برای گروه '..txt[2]..' فعال شد\nاین گروه تا 30 روز دیگر اعتبار دارد! ( 1 ماه )', 1, 'md')
	   send(txt[2], 0, 1, 'ربات با موفقیت فعال شد و تا 30 روز دیگر اعتبار دارد!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User"..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]plan2(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](plan2)(-%d+)$")} 
       local timeplan2 = 7776000
       database:setex("bot:charge:"..txt[2],timeplan2,true)
	   send(msg.chat_id_, msg.id_, 1, 'پلن 2 با موفقیت برای گروه '..txt[2]..' فعال شد\nاین گروه تا 90 روز دیگر اعتبار دارد! ( 3 ماه )', 1, 'md')
	   send(txt[2], 0, 1, 'ربات با موفقیت فعال شد و تا 90 روز دیگر اعتبار دارد!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User"..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]plan3(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](plan3)(-%d+)$")} 
       database:set("bot:charge:"..txt[2],true)
	   send(msg.chat_id_, msg.id_, 1, 'پلن 3 با موفقیت برای گروه '..txt[2]..' فعال شد\nاین گروه به صورت نامحدود شارژ شد!', 1, 'md')
	   send(txt[2], 0, 1, 'ربات بدون محدودیت فعال شد ! ( نامحدود )', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User"..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..txt[2],true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]add') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](add)$")} 
       database:set("bot:charge:"..msg.chat_id_,true)
	   send(msg.chat_id_, msg.id_, 1, '*Done*\nBot Added To Group', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User"..msg.sender_user_id_.." Added bot to new group*" , 1, 'md')
       end
	   database:set("bot:enable:"..msg.chat_id_,true)
  end
  -----------------------------------------------------------------------------------------------
  if text:match('^[#!/]rem') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^[#/!](rem)$")} 
       database:del("bot:charge:"..msg.chat_id_)
	   send(msg.chat_id_, msg.id_, 1, ' *Done*\nBot Removed To Group!', 1, 'md')
	   for k,v in pairs(sudo_users) do
	      send(v, 0, 1, "*User"..msg.sender_user_id_.." Removed bot from new group*" , 1, 'md')
       end
  end
  -----------------------------------------------------------------------------------------------
   if text:match('join(-%d+)') and is_admin(msg.sender_user_id_, msg.chat_id_) then
       local txt = {string.match(text, "^(join)(-%d+)$")} 
	   send(msg.chat_id_, msg.id_, 1, 'با موفقیت تورو به گروه '..txt[3]..' اضافه کردم.', 1, 'md')
	   send(txt[2], 0, 1, '"Sudo Joined To Grpup', 1, 'md')
	   add_user(txt[2], msg.sender_user_id_, 10)
  end
   -----------------------------------------------------------------------------------------------
  end
	-----------------------------------------------------------------------------------------------
	if text:match("^[#!/]reload$") and is_sudo(msg) then
         send(msg.chat_id_, msg.id_, 1, '*Reloaded*', 1, 'md')
    end
	-----------------------------------------------------------------------------------------------
  	if text:match("^[#!/]del (%d+)$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
       local delnumb = {string.match(text, "^[#/!](del) (%d+)$")} 
	   if tonumber(delnumb[2]) > 100 then
			send(msg.chat_id_, msg.id_, 1, 'Error\nuse /del [1-100]', 1, 'md')
else
       local id = msg.id_ - 1
        for i= id - delnumb[2] , id do 
        delete_msg(msg.chat_id_,{[0] = i})
        end
			send(msg.chat_id_, msg.id_, 1, '> '..delnumb[2]..' Last Msgs Has Been Removed.', 1, 'md')
    end
	end
	-----------------------------------------------------------------------------------------------
   if text:match("^[#!/]id$") then
      if is_sudo(msg) then
	  t = '*Sudo*'
      elseif is_admin(msg.sender_user_id_) then
	  t = '*Admin*'
      elseif is_owner(msg.sender_user_id_, msg.chat_id_) then
	  t = '*Owner*'
      elseif is_mod(msg.sender_user_id_, msg.chat_id_) then
	  t = '*Moderator*'
      else
	  t = '*Member*'
	  end
         send(msg.chat_id_, msg.id_, 1, 'Bot ID : *308485826*\n_Your ID : _ *'..msg.sender_user_id_..'*\n_Your Rank :_ '..t, 1, 'md')
    end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]pin$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
        local id = msg.id_
        local msgs = {[0] = id}
       pin(msg.chat_id_,msg.reply_to_message_id_,0)
	   database:set('pinnedmsg'..msg.chat_id_,msg.reply_to_message_id_)
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]unpin$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
         unpinmsg(msg.chat_id_)
         send(msg.chat_id_, msg.id_, 1, 'Pinned Msg han been unpinned!', 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]repin$") and is_owner(msg.sender_user_id_, msg.chat_id_) then
local pin_id = database:get('pinnedmsg'..msg.chat_id_)
        if pin_id then
         pin(msg.chat_id_,pin_id,0)
         send(msg.chat_id_, msg.id_, 1, '*Last Pinned msg has been repinned!*', 1, 'md')
		else
         send(msg.chat_id_, msg.id_, 1, "*i Can't find last pinned msgs...*", 1, 'md')
		 end
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]help$") and is_mod(msg.sender_user_id_, msg.chat_id_) then
   
   local text = [[*
راهنما بزودی کامل میشود!!!*
]]
                send(msg.chat_id_, msg.id_, 1, text, 1, 'md')
   end
   -----------------------------------------------------------------------------------------------
   if text:match("^[#!/]gview$") then
        database:set('bot:viewget'..msg.sender_user_id_,true)
        send(msg.chat_id_, msg.id_, 1, '*Please send a post now!*', 1, 'md')
   end
  end
  -----------------------------------------------------------------------------------------------
 end
  -----------------------------------------------------------------------------------------------
                                       -- end code --
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateChat") then
    chat = data.chat_
    chats[chat.id_] = chat
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateMessageEdited") then
   local msg = data
  -- vardump(msg)
  	function get_msg_contact(extra, result, success)
	local text = (result.content_.text_ or result.content_.caption_)
    --vardump(result)
	if result.id_ and result.content_.text_ then
	database:set('bot:editid'..result.id_,result.content_.text_)
	end
  if not is_mod(result.sender_user_id_, result.chat_id_) then
   check_filter_words(result, text)
   if text:match("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]") or
text:match("[Tt].[Mm][Ee]") or text:match("[Tt][Ll][Gg][Rr][Mm].[Mm][Ee]") then
   if database:get('bot:links:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("[Hh][Tt][Tt][Pp][Ss]://") or text:match("[Hh][Tt][Tt][Pp]://") or text:match(".[Ii][Rr]") or text:match(".[Cc][Oo][Mm]") or text:match(".[Oo][Rr][Gg]") or text:match(".[Ii][Nn][Ff][Oo]") or text:match("[Ww][Ww][Ww].") or text:match(".[Tt][Kk]") then
   if database:get('bot:webpage:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   if text:match("@") then
   if database:get('bot:tag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("#") then
   if database:get('bot:hashtag:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   	if text:match("[\216-\219][\128-\191]") then
   if database:get('bot:arabic:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
   if text:match("[ASDFGHJKLQWERTYUIOPZXCVBNMasdfghjklqwertyuiopzxcvbnm]") then
   if database:get('bot:english:mute'..result.chat_id_) then
    local msgs = {[0] = data.message_id_}
       delete_msg(msg.chat_id_,msgs)
	end
   end
    end
	end
	if database:get('editmsg'..msg.chat_id_) == 'delmsg' then
        local id = msg.message_id_
        local msgs = {[0] = id}
        local chat = msg.chat_id_
              delete_msg(chat,msgs)
	elseif database:get('editmsg'..msg.chat_id_) == 'didam' then
	if database:get('bot:editid'..msg.message_id_) then
		local old_text = database:get('bot:editid'..msg.message_id_)
	    send(msg.chat_id_, msg.message_id_, 1, '_چرا ادیت کردی😉\nمن دیدم که گفتی:_\n*'..old_text..'*', 1, 'md')
	end
	end
    getMessage(msg.chat_id_, msg.message_id_,get_msg_contact)
  -----------------------------------------------------------------------------------------------
  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({ID="GetChats", offset_order_="9223372036854775807", offset_chat_id_=0, limit_=20}, dl_cb, nil)    
  end
  -----------------------------------------------------------------------------------------------
end
