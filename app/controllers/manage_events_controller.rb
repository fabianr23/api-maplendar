class ManageEventsController < ApplicationController
    USERS_MS = "http://192.168.99.103:3001/"
    EVENTS_MS = "http://192.168.99.103:3006/"
    INVITES_MS = "http://192.168.99.103:3005/"
    ATTENDANCE_MS = "http://192.168.99.103:3004/"
    ATTENDANCE_MS2 = "http://192.168.99.103:3004"

        def createEvent
        if request.headers.include? "Authorization"
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"])
                # puts current_user.header['jwt']
                options = {
                    :body => {
                        :name => params[:name],
                        :description => params[:description],
                        :place_id => params[:place_id],
                        :start_time => params[:start_time],
                        :end_time => params[:end_time],
                        :owner_id => current_user["user"]["id"]
                    }.to_json,
			:headers => {
                        	'Content-Type' => 'application/json'
                    }
                }
                result = HTTParty.post(EVENTS_MS + "events", options)
                if result.code == 201
                    render json: {
                        message: "El evento se creó correctamente",
                        event: JSON.parse(result.body),
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
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"])
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

    def getEventsByOwnerId
        if request.headers.include? "Authorization"
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"])
                result = HTTParty.get(EVENTS_MS + "events/owner/" + current_user["user"]["id"].to_s)
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

    def getEventsByPlace
        if request.headers.include? "Authorization"
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"])
                puts params
                result = HTTParty.get(EVENTS_MS + "events/place/" + params[:place_id].to_s)
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
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"])
                @usuarioactual = current_user["user"]
                if event = checkEvent(params[:event_id])
                    puts "event_"
                    puts event
                    options = {
                        :body => {
                            :Invita => {
                                :ID => @usuarioactual["id"],
                                :Email => @usuarioactual["email"]
                            },
                            :Evento => {
                                :ID => event["id"],
                                :Name => event["name"],
                                :Date => event["start_time"],
                                :Hour => event["end_time"],
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
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"]) && event = checkEvent(params[:event_id])
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

    def getMyInvitations
        if request.headers.include? "Authorization"
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"])
                result = HTTParty.get(ATTENDANCE_MS + "api/attendance/?user_id=" + current_user["user"]["id"].to_s  )
                render json: {
                    response: result.parsed_response,
                    token: current_user.header['jwt']
                }, status: :ok
            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
            }, status: :unauthorized
        end
    end

    def defineAttendance
        if request.headers.include? "Authorization"
            if current_user = AuthenticateController.checkToken(request.headers["Authorization"]) && event = checkEvent(params[:event_id])
                options = {
                    :body => {
                        :status => params[:status]
                    }.to_json,
                    :headers => {
                        'Content-Type' => 'application/json'
                    }
                }
		result1 = HTTParty.get(ATTENDANCE_MS + "api/attendance/?event_id=" + event["id"].to_s + "&user_id=" + current_user["user"]["id"].to_s  )
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
end
