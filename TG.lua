function get_sudo ()
	if redis:get("tg:" .. Ads_id .. ":sudoset") then
		return true
	else
    	print("\n\27[36m  Input the sudo id :\n\27[31m                 ")
    	local sudo=io.read()
		redis:del("tg:" .. Ads_id .. ":sudo")
    	redis:sadd("tg:" .. Ads_id .. ":sudo", sudo)
		redis:set("tg:" .. Ads_id .. ":sudoset",true)
    	return print("\n\27[36m     sudo by user id |\27[32m ".. sudo .." \27[36m| register")
	end
end
function get_bot (i, sajjad)
	function bot_info (i, sajjad)
		redis:set("tg:" .. Ads_id .. ":id",sajjad.id_)
		if sajjad.first_name_ then
			redis:set("tg:" .. Ads_id .. ":fname",sajjad.first_name_)
		end
		if sajjad.last_name_ then
			redis:set("tg:" .. Ads_id .. ":lanme",sajjad.last_name_)
		end
		redis:set("tg:" .. Ads_id .. ":num",sajjad.phone_number_)
		return sajjad.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./TG-Ads_id.lua")()
	send(chat_id, msg_id, "<i>با موفقیت انجام شد.</i>")
end
function is_sajjad(msg)
    local var = false
	local hash = "tg:" .. Ads_id .. ":sudo"
	local user = msg.sender_user_id_
    local TGM = redis:sismember(hash, user)
	if TGM then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, sajjad)
	if sajjad.code_ == 429 then
		local message = tostring(sajjad.message_)
		local Time = message:match('%d+') + 85
		redis:setex("tg:" .. Ads_id .. ":maxjoin", tonumber(Time), true)
	else
		redis:srem("tg:" .. Ads_id .. ":goodlinks", i.link)
		redis:sadd("tg:" .. Ads_id .. ":savedlinks", i.link)
	end
end
function process_link(i, sajjad)
	if (sajjad.is_group_ or sajjad.is_supergroup_channel_) then
		redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
		redis:sadd("tg:" .. Ads_id .. ":goodlinks", i.link)
	elseif sajjad.code_ == 429 then
		local message = tostring(sajjad.message_)
		local Time = message:match('%d+') + 85
		redis:setex("tg:" .. Ads_id .. ":maxlink", tonumber(Time), true)
	else
		redis:srem("tg:" .. Ads_id .. ":waitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("tg:" .. Ads_id .. ":alllinks", link) then
				redis:sadd("tg:" .. Ads_id .. ":waitelinks", link)
				redis:sadd("tg:" .. Ads_id .. ":alllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("tg:" .. Ads_id .. ":all", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("tg:" .. Ads_id .. ":users", id)
			redis:sadd("tg:" .. Ads_id .. ":all", id)
		elseif Id:match("^-100") then
			redis:sadd("tg:" .. Ads_id .. ":supergroups", id)
			redis:sadd("tg:" .. Ads_id .. ":all", id)
		else
			redis:sadd("tg:" .. Ads_id .. ":groups", id)
			redis:sadd("tg:" .. Ads_id .. ":all", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("tg:" .. Ads_id .. ":all", id) then
		if Id:match("^(%d+)$") then
			redis:srem("tg:" .. Ads_id .. ":users", id)
			redis:srem("tg:" .. Ads_id .. ":all", id)
		elseif Id:match("^-100") then
			redis:srem("tg:" .. Ads_id .. ":supergroups", id)
			redis:srem("tg:" .. Ads_id .. ":all", id)
		else
			redis:srem("tg:" .. Ads_id .. ":groups", id)
			redis:srem("tg:" .. Ads_id .. ":all", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_sudo()
redis:set("tg:" .. Ads_id .. ":start", true)
function Doing(data, Ads_id)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("tg:" .. Ads_id .. ":maxlink") then
			if redis:scard("tg:" .. Ads_id .. ":waitelinks") ~= 0 then
				local links = redis:smembers("tg:" .. Ads_id .. ":waitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("tg:" .. Ads_id .. ":maxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("tg:" .. Ads_id .. ":maxjoin") then
			if redis:scard("tg:" .. Ads_id .. ":goodlinks") ~= 0 then
				local links = redis:smembers("tg:" .. Ads_id .. ":goodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("tg:" .. Ads_id .. ":maxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("tg:" .. Ads_id .. ":id") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "3⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers("tg:" .. Ads_id .. ":sudo")) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("tg:" .. Ads_id .. ":all", msg.chat_id_) then
				redis:sadd("tg:" .. Ads_id .. ":users", msg.chat_id_)
				redis:sadd("tg:" .. Ads_id .. ":all", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("tg:" .. Ads_id .. ":link") then
				find_link(text)
			end
			if is_sajjad(msg) then
				find_link(text)
				if text:match("^([Dd]el) (.*)$") then
					local matches = text:match("^[Dd]el (.*)$")
					if matches == "goodlinks" then
						redis:del("tg:" .. Ads_id .. ":goodlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت پاکسازی شد.")
					elseif matches == "waitelinks" then
						redis:del("tg:" .. Ads_id .. ":waitelinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید پاکسازی شد.")
					elseif matches == "savedlinks" then
						redis:del("tg:" .. Ads_id .. ":savedlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده پاکسازی شد.")
					end
				elseif text:match("^([Dd]el[Aa]ll) (.*)$") then
					local matches = text:match("^حذف کلی لینک (.*)$")
					if matches == "goodlinks" then
						local list = redis:smembers("tg:" .. Ads_id .. ":goodlinks")
						for i, v in ipairs(list) do
							redis:srem("tg:" .. Ads_id .. ":alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت بطورکلی پاکسازی شد.")
						redis:del("tg:" .. Ads_id .. ":goodlinks")
					elseif matches == "waitelinks" then
						local list = redis:smembers("tg:" .. Ads_id .. ":waitelinks")
						for i, v in ipairs(list) do
							redis:srem("tg:" .. Ads_id .. ":alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید بطورکلی پاکسازی شد.")
						redis:del("tg:" .. Ads_id .. ":waitelinks")
					elseif matches == "savedlinks" then
						local list = redis:smembers("tg:" .. Ads_id .. ":savedlinks")
						for i, v in ipairs(list) do
							redis:srem("tg:" .. Ads_id .. ":alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده بطورکلی پاکسازی شد.")
						redis:del("tg:" .. Ads_id .. ":savedlinks")
					end
				elseif text:match("^([Ss]top) (.*)$") then
					local matches = text:match("^[Ss]top (.*)$")
					if matches == "[Jj]oin" then	
						redis:set("tg:" .. Ads_id .. ":maxjoin", true)
						redis:set("tg:" .. Ads_id .. ":offjoin", true)
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار متوقف شد.")
					elseif matches == "[Cc]heck[Ll]ink" then	
						redis:set("tg:" .. Ads_id .. ":maxlink", true)
						redis:set("tg:" .. Ads_id .. ":offlink", true)
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک در های در انتظار متوقف شد.")
					elseif matches == "[Ff]ind[Ll]ink" then	
						redis:del("tg:" .. Ads_id .. ":link")
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک متوقف شد.")
					elseif matches == "[Aa]dd[Cc]ontact" then	
						redis:del("tg:" .. Ads_id .. ":savecontacts")
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک گذاشته شده متوقف شد.")
					end
				elseif text:match("^([Ss]tart) (.*)$") then
					local matches = text:match("^[Ss]tart (.*)$")
					if matches == "[Jj]oin" then	
						redis:del("tg:" .. Ads_id .. ":maxjoin")
						redis:del("tg:" .. Ads_id .. ":offjoin")
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خودکار فعال شد.")
					elseif matches == "[Cc]heck[Ll]ink" then	
						redis:del("tg:" .. Ads_id .. ":maxlink")
						redis:del("tg:" .. Ads_id .. ":offlink")
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک های در انتظار فعال شد.")
					elseif matches == "[Ff]ind[Ll]ink" then	
						redis:set("tg:" .. Ads_id .. ":link", true)
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک فعال شد.")
					elseif matches == "[Aa]dd[Cc]ontact" then	
						redis:set("tg:" .. Ads_id .. ":savecontacts", true)
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکار مخاطبین به اشتراک  گذاشته شده فعال شد.")
					end
				elseif text:match("^([Pp]romote) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
						return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر در حال حاضر مدیر است.</i>")
					elseif redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					else
						redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
						redis:sadd("tg:" .. Ads_id .. ":mod", matches)
						return send(msg.chat_id_, msg.id_, "<i>مقام کاربر به مدیر ارتقا یافت</i>")
					end
				elseif text:match("^([Aa]dd[Ss]udo) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember("tg:" .. Ads_id .. ":mod",msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember("tg:" .. Ads_id .. ":mod", matches) then
						redis:srem("tg:" .. Ads_id .. ":mod",matches)
						redis:sadd("tg:" .. Ads_id .. ":sudo"..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "مقام کاربر به مدیریت کل ارتقا یافت .")
					elseif redis:sismember("tg:" .. Ads_id .. ":sudo",matches) then
						return send(msg.chat_id_, msg.id_, 'درحال حاضر مدیر هستند.')
					else
						redis:sadd("tg:" .. Ads_id .. ":sudo", matches)
						redis:sadd("tg:" .. Ads_id .. ":sudo"..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر به مقام مدیرکل منصوب شد.")
					end
				elseif text:match("^([Dd]emote) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember("tg:" .. Ads_id .. ":mod", msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem("tg:" .. Ads_id .. ":sudo", msg.sender_user_id_)
								redis:srem("tg:" .. Ads_id .. ":mod", msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شما دیگر مدیر نیستید.")
						end
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember("tg:" .. Ads_id .. ":sudo", matches) then
						if  redis:sismember("tg:" .. Ads_id .. ":sudo"..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری که به شما مقام داده را عزل کنید.")
						end
						redis:srem("tg:" .. Ads_id .. ":sudo", matches)
						redis:srem("tg:" .. Ads_id .. ":mod", matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مدیریت خلع شد.")
					end
					return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مدیر نمی باشد.")
				elseif text:match("^([Rr]efresh)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>مشخصات فردی ربات بروز شد.</i>")
				elseif text:match("[Rr]eport") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^([Rr]eload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^[Uu]p[Dd]ate$") then
					io.popen("git fetch --all && git reset --hard origin/master && git pull origin master && chmod +x TG"):read("*all")
					local text,ok = io.open("TG.lua",'r'):read('*a'):gsub("ADS%-ID",Ads_id)
					io.open("TG-Ads_id.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^([Ll]ist) (.*)$") then
					local matches = text:match("^لیست (.*)$")
					local sajjad
					if matches == "[Cc]ontact" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, TGM)
							local count = TGM.total_count_
							local text = "Contact's List : \n"
							for i =0 , tonumber(count) - 1 do
								local user = TGM.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("tg:" .. Ads_id .. ":_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "tg:" .. Ads_id .. ":_contacts.txt"},
								caption_ = "مخاطبین تبلیغ‌گر شماره Ads_id"}
							}, dl_cb, nil)
							return io.popen("rm -rf tg:" .. Ads_id .. ":_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پاسخ های خودکار" then
						local text = "<i>لیست پاسخ های خودکار :</i>\n\n"
						local answers = redis:smembers("tg:" .. Ads_id .. ":answerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("tg:" .. Ads_id .. ":answers", v)) .. "\n"
						end
						if redis:scard("tg:" .. Ads_id .. ":answerslist") == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "مسدود" then
						sajjad = "tg:" .. Ads_id .. ":blockedusers"
					elseif matches == "شخصی" then
						sajjad = "tg:" .. Ads_id .. ":users"
					elseif matches == "گروه" then
						sajjad = "tg:" .. Ads_id .. ":groups"
					elseif matches == "سوپرگروه" then
						sajjad = "tg:" .. Ads_id .. ":supergroups"
					elseif matches == "لینک" then
						sajjad = "tg:" .. Ads_id .. ":savedlinks"
					elseif matches == "مدیر" then
						sajjad = "tg:" .. Ads_id .. ":sudo"
					else
						return true
					end
					local list =  redis:smembers(sajjad)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(sajjad)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(sajjad)..".txt"},
						caption_ = "لیست "..tostring(matches).." های تبلیغ گر شماره Ads_id"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(sajjad)..".txt"):read("*all")
				elseif text:match("^([Mm]ark[Rr]ead) (.*)$") then
					local matches = text:match("^[Mm]ark[Rr]ead (.*)$")
					if matches == "[Oo]n" then
						redis:set("tg:" .. Ads_id .. ":markread", true)
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده شده ✔️✔️\n</i><code>(تیک دوم فعال)</code>")
					elseif matches == "[Oo]ff" then
						redis:del("tg:" .. Ads_id .. ":markread")
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام ها  >>  خوانده نشده ✔️\n</i><code>(بدون تیک دوم)</code>")
					end 
				elseif text:match("^(افزودن با پیام) (.*)$") then
					local matches = text:match("^افزودن با پیام (.*)$")
					if matches == "روشن" then
						redis:set("tg:" .. Ads_id .. ":addmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("tg:" .. Ads_id .. ":addmsg")
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(افزودن با شماره) (.*)$") then
					local matches = text:match("افزودن با شماره (.*)$")
					if matches == "روشن" then
						redis:set("tg:" .. Ads_id .. ":addcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("tg:" .. Ads_id .. ":addcontact")
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره هنگام افزودن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
					local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
					redis:set("tg:" .. Ads_id .. ":addmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب ثبت  شد </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
					local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
					redis:hset("tg:" .. Ads_id .. ":answers", txt, answer)
					redis:sadd("tg:" .. Ads_id .. ":answerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(txt) .. "<i> | تنظیم شد به :</i>\n" .. tostring(answer))
				elseif text:match("^(حذف جواب) (.*)") then
					local matches = text:match("^حذف جواب (.*)")
					redis:hdel("tg:" .. Ads_id .. ":answers", matches)
					redis:srem("tg:" .. Ads_id .. ":answerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(matches) .. "<i> | از لیست جواب های خودکار پاک شد.</i>")
				elseif text:match("^(پاسخگوی خودکار) (.*)$") then
					local matches = text:match("^پاسخگوی خودکار (.*)$")
					if matches == "روشن" then
						redis:set("tg:" .. Ads_id .. ":autoanswer", true)
						return send(msg.chat_id_, 0, "<i>پاسخگویی خودکار تبلیغ گر فعال شد</i>")
					elseif matches == "خاموش" then
						redis:del("tg:" .. Ads_id .. ":autoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خودکار تبلیغ گر غیر فعال شد.</i>")
					end
				elseif text:match("^(تازه سازی)$")then
					local list = {redis:smembers("tg:" .. Ads_id .. ":supergroups"),redis:smembers("tg:" .. Ads_id .. ":groups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, sajjad)
						redis:set("tg:" .. Ads_id .. ":contacts", sajjad.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,sajjad)
									if  sajjad.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>تازه‌سازی آمار تبلیغ‌گر شماره </i><code> Ads_id </code> با موفقیت انجام شد.")
				elseif text:match("^([Ii]nfo)$") then
					local s =  redis:get("tg:" .. Ads_id .. ":offjoin") and 0 or redis:get("tg:" .. Ads_id .. ":maxjoin") and redis:ttl("tg:" .. Ads_id .. ":maxjoin") or 0
					local ss = redis:get("tg:" .. Ads_id .. ":offlink") and 0 or redis:get("tg:" .. Ads_id .. ":maxlink") and redis:ttl("tg:" .. Ads_id .. ":maxlink") or 0
					local msgadd = redis:get("tg:" .. Ads_id .. ":addmsg") and "✅️" or "⛔️"
					local numadd = redis:get("tg:" .. Ads_id .. ":addcontact") and "✅️" or "⛔️"
					local txtadd = redis:get("tg:" .. Ads_id .. ":addmsgtext") or  "اد‌دی گلم خصوصی پیام بده"
					local autoanswer = redis:get("tg:" .. Ads_id .. ":autoanswer") and "✅️" or "⛔️"
					local wlinks = redis:scard("tg:" .. Ads_id .. ":waitelinks")
					local glinks = redis:scard("tg:" .. Ads_id .. ":goodlinks")
					local links = redis:scard("tg:" .. Ads_id .. ":savedlinks")
					local offjoin = redis:get("tg:" .. Ads_id .. ":offjoin") and "⛔️" or "✅️"
					local offlink = redis:get("tg:" .. Ads_id .. ":offlink") and "⛔️" or "✅️"
					local nlink = redis:get("tg:" .. Ads_id .. ":link") and "✅️" or "⛔️"
					local contacts = redis:get("tg:" .. Ads_id .. ":savecontacts") and "✅️" or "⛔️"
					local txt = "⚙️  <i>وضعیت اجرایی تبلیغ‌گر</i><code> Ads_id</code>  ⛓\n\n"..tostring(offjoin).."<code> عضویت خودکار </code>🚀\n"..tostring(offlink).."<code> تایید لینک خودکار </code>🚦\n"..tostring(nlink).."<code> تشخیص لینک های عضویت </code>🎯\n"..tostring(contacts).."<code> افزودن خودکار مخاطبین </code>➕\n" .. tostring(autoanswer) .."<code> حالت پاسخگویی خودکار 🗣 </code>\n" .. tostring(numadd) .. "<code> افزودن مخاطب با شماره 📞 </code>\n" .. tostring(msgadd) .. "<code> افزودن مخاطب با پیام 🗞</code>\n〰〰〰ا〰〰〰\n📄<code> پیام افزودن مخاطب :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n<code>📁 لینک های ذخیره شده : </code><b>" .. tostring(links) .. "</b>\n<code>⏲	لینک های در انتظار عضویت : </code><b>" .. tostring(glinks) .. "</b>\n🕖   <b>" .. tostring(s) .. " </b><code>ثانیه تا عضویت مجدد</code>\n<code>❄️ لینک های در انتظار تایید : </code><b>" .. tostring(wlinks) .. "</b>\n🕑️   <b>" .. tostring(ss) .. " </b><code>ثانیه تا تایید لینک مجدد</code>\n\n 😼 سازنده : @i_sajjad"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^([Pp]anel)$") or text:match("^(/[Pp]anel)$") then
					local gps = redis:scard("tg:" .. Ads_id .. ":groups")
					local sgps = redis:scard("tg:" .. Ads_id .. ":supergroups")
					local usrs = redis:scard("tg:" .. Ads_id .. ":users")
					local links = redis:scard("tg:" .. Ads_id .. ":savedlinks")
					local glinks = redis:scard("tg:" .. Ads_id .. ":goodlinks")
					local wlinks = redis:scard("tg:" .. Ads_id .. ":waitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, sajjad)
					redis:set("tg:" .. Ads_id .. ":contacts", sajjad.total_count_)
					end, nil)
					local contacts = redis:get("tg:" .. Ads_id .. ":contacts")
					local text = [[
<i>📈 وضعیت و آمار تبلیغ گر 📊</i>
          
<code>👤 گفت و گو های شخصی : </code>
<b>]] .. tostring(usrs) .. [[</b>
<code>👥 گروها : </code>
<b>]] .. tostring(gps) .. [[</b>
<code>🌐 سوپر گروه ها : </code>
<b>]] .. tostring(sgps) .. [[</b>
<code>📖 مخاطبین دخیره شده : </code>
<b>]] .. tostring(contacts)..[[</b>
<code>📂 لینک های ذخیره شده : </code>
<b>]] .. tostring(links)..[[</b>
 😼 سازنده : @i_sajjad]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local sajjad
					if matches:match("^(خصوصی)") then
						sajjad = "tg:" .. Ads_id .. ":users"
					elseif matches:match("^(گروه)$") then
						sajjad = "tg:" .. Ads_id .. ":groups"
					elseif matches:match("^(سوپرگروه)$") then
						sajjad = "tg:" .. Ads_id .. ":supergroups"
					else
						return true
					end
					local list = redis:smembers(sajjad)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(ارسال به سوپرگروه) (.*)") then
					local matches = text:match("^ارسال به سوپرگروه (.*)")
					local dir = redis:smembers("tg:" .. Ads_id .. ":supergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("tg:" .. Ads_id .. ":blockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر مسدود شد</i>")
				elseif text:match("^(رفع مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("tg:" .. Ads_id .. ":blockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>مسدودیت کاربر مورد نظر رفع شد.</i>")	
				elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
					local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت ثبت شد.</i>")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری...</i>')
				elseif text:match("^(حذف نام کاربری)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت حذف شد.</i>')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال شد</i>")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(شناسه من)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(ترک کردن) (.*)$") then
					local matches = text:match("^ترک کردن (.*)$") 	
					send(msg.chat_id_, msg.id_, 'تبلیغ‌گر از گروه مورد نظر خارج شد')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(افزودن به همه) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("tg:" .. Ads_id .. ":groups"),redis:smembers("tg:" .. Ads_id .. ":supergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر به تمام گروه های من دعوت شد</i>")
				elseif (text:match("^(انلاین)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^([Hh]elp)$") then
					local txt = '📍راهنمای دستورات تبلیغ‌گر📍\n\nانلاین\n<i>اعلام وضعیت تبلیغ‌گر ✔️</i>\n<code>❤️ حتی اگر تبلیغ‌گر شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️</code>\n/reload\n<i>l🔄 بارگذاری مجدد ربات 🔄l</i>\n<code>I⛔️عدم استفاده بی جهت⛔️I</code>\nبروزرسانی ربات\n<i>بروزرسانی ربات به آخرین نسخه و بارگذاری مجدد 🆕</i>\n\nافزودن مدیر شناسه\n<i>افزودن مدیر جدید با شناسه عددی داده شده 🛂</i>\n\nافزودن مدیرکل شناسه\n<i>افزودن مدیرکل جدید با شناسه عددی داده شده 🛂</i>\n\n<code>(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)</code>\n\nحذف مدیر شناسه\n<i>حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️</i>\n\nترک گروه\n<i>خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃</i>\n\nافزودن همه مخاطبین\n<i>افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕</i>\n\nشناسه من\n<i>دریافت شناسه خود 🆔</i>\n\nبگو متن\n<i>دریافت متن 🗣</i>\n\nارسال کن "شناسه" متن\n<i>ارسال متن به شناسه گروه یا کاربر داده شده 📤</i>\n\nتنظیم نام "نام" فامیل\n<i>تنظیم نام ربات ✏️</i>\n\nتازه سازی ربات\n<i>تازه‌سازی اطلاعات فردی ربات🎈</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نام📍جهت بروزکردن نام مخاطب اشتراکی تبلیغ‌گر📍)</code>\n\nتنظیم نام کاربری اسم\n<i>جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄</i>\n\nحذف نام کاربری\n<i>حذف کردن نام کاربری ❎</i>\n\nتوقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>غیر‌فعال کردن فرایند خواسته شده</i> ◼️\n\nشروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>فعال‌سازی فرایند خواسته شده</i> ◻️\n\nافزودن با شماره روشن|خاموش\n<i>تغییر وضعیت اشتراک شماره تبلیغ‌گر در جواب شماره به اشتراک گذاشته شده 🔖</i>\n\nافزودن با پیام روشن|خاموش\n<i>تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️</i>\n\nتنظیم پیام افزودن مخاطب متن\n<i>تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨</i>\n\nلیست مخاطبین|خصوصی|گروه|سوپرگروه|پاسخ های خودکار|لینک|مدیر\n<i>دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 📄</i>\n\nمسدودیت شناسه\n<i>مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی 🚫</i>\n\nرفع مسدودیت شناسه\n<i>رفع مسدودیت کاربر با شناسه داده شده 💢</i>\n\nوضعیت مشاهده روشن|خاموش 👁\n<i>تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)</i>\n\nامار\n<i>دریافت آمار و وضعیت تبلیغ‌گر 📊</i>\n\nوضعیت\n<i>دریافت وضعیت اجرایی تبلیغ‌گر⚙️</i>\n\nتازه سازی\n<i>تازه‌سازی آمار تبلیغ‌گر🚀</i>\n<code>🎃مورد استفاده حداکثر یک بار در روز🎃</code>\n\nارسال به همه|خصوصی|گروه|سوپرگروه\n<i>ارسال پیام جواب داده شده به مورد خواسته شده 📩</i>\n<code>(😄توصیه ما عدم استفاده از همه و خصوصی😄)</code>\n\nارسال به سوپرگروه متن\n<i>ارسال متن داده شده به همه سوپرگروه ها ✉️</i>\n<code>(😜توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😜)</code>\n\nتنظیم جواب "متن" جواب\n<i>تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📝</i>\n\nحذف جواب متن\n<i>حذف جواب مربوط به متن ✖️</i>\n\nپاسخگوی خودکار روشن|خاموش\n<i>تغییر وضعیت پاسخگویی خودکار تبلیغ‌گر به متن های تنظیم شده 📯</i>\n\nحذف لینک عضویت|تایید|ذخیره شده\n<i>حذف لیست لینک‌های مورد نظر </i>❌\n\nحذف کلی لینک عضویت|تایید|ذخیره شده\n<i>حذف کلی لیست لینک‌های مورد نظر </i>💢\n🔺<code>پذیرفتن مجدد لینک در صورت حذف کلی</code>🔻\n\nافزودن به همه شناسه\n<i>افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها ➕➕</i>\n\nترک کردن شناسه\n<i>عملیات ترک کردن با استفاده از شناسه گروه 🏃</i>\n\nراهنما\n<i>دریافت همین پیام 🆘</i>\n〰〰〰ا〰〰〰\nهمگام سازی با تبچی\n<code>همگام سازی اطلاعات تبلیغ‌گر با اطلاعات تبچی از قبل نصب شده 🔃 (جهت این امر حتما به ویدیو آموزشی کانال مراجعه کنید)</code>\n〰〰〰ا〰〰〰\nسازنده : @I_TGM \nکانال : @I_Advertiser\n<i>آدرس سورس تبلیغ‌گر (کاملا فارسی) :</i>\nhttps://github.com/i-TGM/tabchi/tree/persian\n<code>آخرین اخبار و رویداد های تبلیغ‌گر را در کانال ما پیگیری کنید.</code>'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(ترک کردن)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(افزودن همه مخاطبین)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, sajjad)
							local users, count = redis:smembers("tg:" .. Ads_id .. ":users"), sajjad.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = sajjad.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>در حال افزودن مخاطبین به گروه ...</i>")
					end
				end
			end
			if redis:sismember("tg:" .. Ads_id .. ":answerslist", text) then
				if redis:get("tg:" .. Ads_id .. ":autoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("tg:" .. Ads_id .. ":answers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("tg:" .. Ads_id .. ":savecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("tg:" .. Ads_id .. ":addedcontacts",id) then
				redis:sadd("tg:" .. Ads_id .. ":addedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("tg:" .. Ads_id .. ":addcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("tg:" .. Ads_id .. ":fname")
					local lnasme = redis:get("tg:" .. Ads_id .. ":lname") or ""
					local num = redis:get("tg:" .. Ads_id .. ":num")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("tg:" .. Ads_id .. ":addmsg") then
				local answer = redis:get("tg:" .. Ads_id .. ":addmsgtext") or "اددی گلم خصوصی پیام بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("tg:" .. Ads_id .. ":link"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("tg:" .. Ads_id .. ":markread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 1000
		}, dl_cb, nil)
	end
end
