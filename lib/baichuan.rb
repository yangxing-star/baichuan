require "baichuan/version"

module Baichuan
  class Client

    ACTION_ADD_USERS = 'taobao.openim.users.add'
    ACTION_GET_USERS = 'taobao.openim.users.get'
    ACTION_UPDATE_USERS = 'taobao.openim.users.update'
    ACTION_DELETE_USERS = 'taobao.openim.users.delete'

    ACTION_CUSTMSG_PUSH = 'taobao.openim.custmsg.push'
    ACTION_IMMSG_PUSH = 'taobao.openim.immsg.push'
    ACTION_SEND_GROUP_MSG = 'taobao.openim.tribe.sendmsg'

    ACTION_GET_RELATIONS = 'taobao.openim.relations.get'
    ACTION_GET_CHATLOGS = 'taobao.openim.chatlogs.get'

    ACTION_CREATE_GROUP = 'taobao.openim.tribe.create'
    ACTION_GET_GROUP = 'taobao.openim.tribe.gettribeinfo'
    ACTION_JOIN_GROUP = 'taobao.openim.tribe.join'
    ACTION_INVITE_GROUP = 'taobao.openim.tribe.invite'
    ACTION_QUIT_GROUP = 'taobao.openim.tribe.quit'
    ACTION_EXPEL_GROUP = 'taobao.openim.tribe.expel'
    ACTION_DISSMISS_GROUP = 'taobao.openim.tribe.dismiss'
    ACTION_SET_MANAGER = 'taobao.openim.tribe.setmanager'
    ACTION_GET_MEMBERS = 'taobao.openim.tribe.getmembers'
    ACTION_UNSET_MANAGER = 'taobao.openim.tribe.unsetmanager'
    ACTION_GET_ALL_GROUPS = 'taobao.openim.tribe.getalltribes'
    ACTION_UPDATE_GROUP = 'taobao.openim.tribe.modifytribeinfo'
    ACTION_SET_MEMBER_NICK = 'taobao.openim.tribe.setmembernick'

    ACTION_IMPORT_CHAT_LOGS = 'taobao.openim.chatlogs.import'
    ACTION_IMPORT_GROUP_LOGS = 'taobao.openim.tribelogs.import'
    ACTION_GET_GROUP_LOGS = 'taobao.openim.tribelogs.get'
    ACTION_GET_APP_CHAT_LOGS = 'taobao.openim.app.chatlogs.get'

    ACTION_GET_DETAILS = 'taobao.openim.track.getdetails'
    ACTION_GET_SUMMARY = 'taobao.openim.track.getsummary'

    def initialize(app_key, secret, sandbox = false)
      @version = 1.0
      @api_host = sandbox ? 'https://gw.api.tbsandbox.com/router/rest' : 'https://eco.taobao.com/router/rest'
      @app_key = app_key || ENV['app_key']
      @secret = secret || ENV['secret']
    end

    def make_signature(params)
      Digest::MD5.hexdigest("#{@secret}#{params.sort.join}#{@secret}").upcase
    end

    def header
      {
        'User-Agent'   => 'BaiChuanSdk/BaiChuan-Ruby-Sdk #{RUBY_VERSION} (#{@version})',
        'Content-Type' => 'application/x-www-form-urlencoded;charset=utf-8'
      }
    end

    def common_params(action)
      {
        method: action,
        app_key: @app_key,
        timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        format: 'json',
        v: '2.0',
        sign_method: 'md5'
      }
    end

    def http_call(url, data)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.ssl_version = :TLSv1
      http.ciphers = ['RC4-SHA']
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = Net::HTTP::Post.new(uri.path, initheader = header)
      req.body = URI.encode_www_form(data)
      res = http.request(req)
      response_object(JSON.parse(res.body))
    end

    def response_object(body)
      response = Struct.new(:success, :data).new
      response.success = !body.has_key?('error_response')
      response.data = body
      response
    end

    def post(action, params)
      params = common_params(action).merge(params)
      params.merge!(sign: make_signature(params))
      http_call(@api_host, params)
    end

    def cust_msg_push(cust_msg)
      post( ACTION_CUSTMSG_PUSH, { custmsg: cust_msg.to_json } )
    end

    def im_msg_push(im_msg)
      post( ACTION_IMMSG_PUSH, { immsg: im_msg.to_json } )
    end

    def add_users(userinfos)
      post( ACTION_ADD_USERS, { userinfos: userinfos.to_json } )
    end

    def get_users(user_ids)
      post( ACTION_GET_USERS, { userids: user_ids.join(',') } )
    end

    def update_users(userinfos)
      post( ACTION_UPDATE_USERS, { userinfos: userinfos.to_json } )
    end

    def delete_users(user_ids)
      post( ACTION_DELETE_USERS, { userids: user_ids.join(',') } )
    end

    def get_relations(user, beg_date, end_date)
      post( ACTION_GET_RELATIONS, { user: user, beg_date: beg_date, end_date: end_date })
    end

    def send_group_msg(member, group_id, msg)
      post( ACTION_SEND_GROUP_MSG, { user: member, tribe_id: group_id, msg: msg })
    end

    def create_group(master, group_name, notice, members, tribe_type = 1)
      post( ACTION_CREATE_GROUP, { user: master,
                                   tribe_name: group_name,
                                   notice: notice,
                                   members: members,
                                   tribe_type: tribe_type
                                 }
          )
    end

    def invite_group(master, group_id, members)
      post( ACTION_INVITE_GROUP, { tribe_id: group_id,
                                   user: master,
                                   members: members
                                 }
          )
    end

    def join_group(member, group_id)
      post( ACTION_JOIN_GROUP, { user: member, tribe_id: group_id } )
    end

    def expel_group(master, group_id, member)
      post( ACTION_EXPEL_GROUP, { tribe_id: group_id,
                                  user: master,
                                  member: member
                                }
          )
    end

    def quit_group(member, group_id)
      post( ACTION_QUIT_GROUP, { tribe_id: group_id, user: member } )
    end

    def dismiss_group(master, group_id)
      post( ACTION_DISMISS_GROUP, { tribe_id: group_id, user: master } )
    end

    def get_group(master, group_id)
      post( ACTION_GET_GROUP, { tribe_id: group_id, user: master } )
    end

    def update_group(master, group_id, group_name, notice)
      post( ACTION_UPDATE_GROUP, { tribe_id: group_id,
                                   tribe_name: group_name,
                                   notice: notice,
                                   user: master
                                 }
          )
    end

    def set_manager(master, group_id, member)
      post( ACTION_SET_MANAGER, { user: master, tid: group_id, member: member } )
    end

    def unset_manager(master, group_id, member)
      post( ACTION_UNSET_MANAGER, { user: master, tid: group_id, member: member } )
    end

    def get_members(member, group_id)
      post( ACTION_GET_MEMBERS, { user: member, tribe_id: group_id } )
    end

    def get_all_group(user, group_types = [0])
      post( ACTION_GET_ALL_GROUP, { user: user, tribe_types: group_types } )
    end

    def set_member_nick(master, group_id, member, nick)
      post( ACTION_SET_MEMBER_NICK, { user: master,
                                      tribe_id: group_id,
                                      member: member,
                                      nick: nick
                                    }
          )
    end

    def get_group_logs(group_id, begin_time, end_time, count)
      post( ACTION_GET_GROUP_LOGS, { tribe_id: group_id, begin: begin_time, end: end_time, count: count } )
    end

    def import_group_logs(group_id, messages)
      post( ACTION_IMPORT_GROUP_LOGS, { tribe_id: group_id, messages: messages } )
    end

    def import_chat_logs(messages)
      post( ACTION_IMPORT_CHAT_LOGS, { messages: messages } )
    end

    def get_details(im_id, start_time, end_time)
      post( ACTION_GET_DETAILS, { uid: im_id, starttime: start_time, endtime: end_time } )
    end

    def get_summary(im_id)
      post( ACTION_GET_SUMMARY, { uid: im_id } )
    end

    def get_app_chat_logs(begin_time, end_time, count)
      post( ACTION_GET_APP_CHAT_LOGS, { beg: begin_time, end: end_time, count: count } )
    end
  end
end
