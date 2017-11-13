class ManageEventsController < ApplicationController
    USERS_MS = "http://192.168.99.103:3001/"
    EVENTS_MS = "http://192.168.99.103:3006/"
    INVITES_MS = "http://192.168.99.103:3005/"
    ATTENDANCE_MS = "http://192.168.99.103:3004/"
    ATTENDANCE_MS2 = "http://192.168.99.103:3004"

    def createEvent
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                # puts current_user.header['jwt']
                puts current_user
                @usuarioactual = current_user["user"]
                options = {
                    :body => {
                        :name => params[:name],
                        :description => params[:description],
                        :site_id => params[:site_id],
                        :start_time => params[:start_time],
                        :end_time => params[:end_time],
                        :owner_id => @usuarioactual["id"]
                    }.to_json,
			:headers => {
                        	'Content-Type' => 'application/json'
                    }
                }
                result = HTTParty.post(EVENTS_MS + "events", options)
                if result.code == 201
                    render json: {
                        message: "El evento se creó correctamente",
                        user: JSON.parse(result.body),
                        token: current_user.header['jwt']
                    }, status: :created
                else
                    render json: {
                        message: "Ocurrió un error al crear el evento",
                        errors: JSON.parse(result.body),
                        token: current_user.header['jwt']
                    }, status: :bad_request
                end
            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
            }, status: :unauthorized
        end
    end

    def getEvents
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                result = HTTParty.get(EVENTS_MS + "events")
                if result.code == 200
                    render json: {
                        events: JSON.parse(result.body),
                        token: current_user.header['jwt']
                    }, status: :ok
                else
                    render json: {
                        message: "Ocurrió un error al obtener los eventos",
                        errors: JSON.parse(result.body),
                        token: current_user.header['jwt']
                    }, status: :bad_request
                end
            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
            }, status: :unauthorized
        end
    end

    def getMyEvents
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                @usuarioactual = current_user["user"]
                puts "id usuario: "
                puts @usuarioactual["id"]
                result = HTTParty.get(EVENTS_MS + "view/my_events?owner_id=" + @usuarioactual["id"].to_s)
                if result.code == 200
                    render json: {
                        events: JSON.parse(result.body),
                        token: current_user.header['jwt']
                    }, status: :ok
                else
                    render json: {
                        message: "Ocurrió un error al obtener los eventos",
                        errors: JSON.parse(result.body),
                        token: current_user.header['jwt']
                    }, status: :bad_request
                end
            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
            }, status: :unauthorized
        end
    end

    def getSites
        result = HTTParty.get(EVENTS_MS + "sites")
        if result.code == 200
            render json: {
                sites: JSON.parse(result.body)
            }, status: :ok
        else
            render json: {
                message: "Ocurrió un error al obtener los sitios",
                errors: JSON.parse(result.body),
            }, status: :bad_request
        end
    end

    def getEventsBySite
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                result = HTTParty.get(EVENTS_MS + "view/events_site/" + params[:site_id].to_s)
                if result.code == 200
                    render json: {
                        events: JSON.parse(result.body),
                        token: current_user.header['jwt']                        
                    }, status: :ok
                else
                    render json: {
                        message: "Ocurrió un error al obtener los eventos",
                        errors: JSON.parse(result.body),
                        token: current_user.header['jwt']                        
                    }, status: :bad_request
                end
            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
            }, status: :unauthorized
        end
    end

    def inviteUsers
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                puts "current user"
                puts current_user
                puts "user:_"
                puts current_user["user"]
                @usuarioactual = current_user["user"]
                puts "user:_id"
                puts @usuarioactual["id"]
                if event = checkEvent(params[:event_id])
                    options = {
                        :body => {
                            :Invita => {
                                :ID => @usuarioactual["id"],
                                :Email => @usuarioactual["email"]
                            },
                            :Evento => {
                                :ID => event["id"],
                                :Name => event["name"],
                                :Date => event["startTime"],
                                :Hour => event["startTime"],
                                :Place => event["address"],
                            },
                            :Invitados => params[:invites]
                        }.to_json,
                        :headers => {
                            'Content-Type' => 'application/json'
                        }
                    }
                    result = HTTParty.post(INVITES_MS + "api/invitaciones/", options)
                    if result["statusCode"] == 201
                        response = ''
                        result["data"].each do |data|
                            options_attendance = {
                                :body => {
                                    :user_id => data["ID_user"],
                                    :event_id => event["id"],
                                    :status => 0
                                }.to_json,
                                :headers => {
                                    'Content-Type' => 'application/json'
                                }
                            }
                            response = HTTParty.post(ATTENDANCE_MS + "api/attendance/", options_attendance)
                            puts response.parsed_response
                            if response.parsed_response["code"] != 201
                                break
                            end
                        end
                        if response.parsed_response["code"] != 201
                            render json: {
                                message: "Ocurrió un error al registrar la asistencia de los usuarios",
                                errors: response.parsed_response,
                                token: current_user.header['jwt']
                            }, status: :bad_request
                        else
                            render json: {
                                message: "Se invitaron los usuarios correctamente",
                                token: current_user.header['jwt']
                            }, status: :ok
                        end
                    else
                        render json: {
                            message: "Ocurrió un error al invitar a los usuarios",
                            errors: JSON.parse(result.body),
                            token: current_user.header['jwt']
                        }, status: :bad_request
                    end

                end

            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
            }, status: :unauthorized
        end
    end

    def getEventWithAttendance
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"]) && event = checkEvent(params[:event_id])
              invitations = getInvitations(params[:event_id])
                if invitations
                  puts invitations
                  attendance = getAttendance(params[:event_id])
                  if attendance
                    render json: {
                        event: JSON.parse(event.body),
                        invitations: invitations.parsed_response,
                        attendance: attendance.parsed_response,
                        token: current_user.header['jwt']
                    }, status: :ok
                  end
                end
            end
        end
    end

    def defineAttendance
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"]) && event = checkEvent(params[:event_id])
                options = {
                    :body => {
                        :status => params[:status]
                    }.to_json,
                    :headers => {
                        'Content-Type' => 'application/json'
                    }
                }
		result1 = HTTParty.get(ATTENDANCE_MS + "api/attendance/?event_id=" + event["id"].to_s + "&user_id=" + current_user["id"].to_s  )
		objects = result1.parsed_response["objects"]
		puts objects
		puts "resource_uri"
 		uri = objects.first["resource_uri"]
		puts uri
                result = HTTParty.put(ATTENDANCE_MS2 + uri  , options )
                if result["code"] == 200
                    render json: {
                        message: "Se cambió el estado de asistencia correctamente",
                        token: current_user.header['jwt']
                    }, status: :ok
                else
                    render json: {
                        message: "Ocurrió un error al asignar la asistencia",
                        errors: result.parsed_response,
                        token: current_user.header['jwt']
                    }, status: :bad_request
                end
            end
        end
    end

    def getAttendance(id)
        result = HTTParty.get(ATTENDANCE_MS + "api/attendance/?event_id=" + id.to_s )

            return result

    end

    def getInvitations(id)
        result = HTTParty.get(INVITES_MS + "api/invitaciones/" + id.to_s)
        if result.code == 200
            return result
        else
            render json: {
                message: "El evento no registra invitaciones",
                token: current_user.header['jwt']
            }, status: :bad_request
            return false
        end
    end

    def checkEvent(id)
        result = HTTParty.get(EVENTS_MS + "events/" + id.to_s)
        if result.code == 200
            return result
        else
            render json: {
                message: "El evento no existe o ya expiró",
                token: current_user.header['jwt']
            }, status: :unauthorized
        end
    end

    def checkToken(token)
        options = {
            :headers => {
                'Accept' => 'application/json',
                'Authorization' => token
            }
        }
        result = HTTParty.get(USERS_MS + "authorize", options)

        if result.code == 200
            return result
        else
            render json: {
                message: "El token no es valido o ya expriró",
            }, status: :unauthorized
            return false
        end
    end
end
