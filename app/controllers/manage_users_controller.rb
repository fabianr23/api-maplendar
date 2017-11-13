class ManageUsersController < ApplicationController
    USERS_MS = "http://192.168.99.103:3001/"
    def createUser
        options = {
            :body => {
                :user => {
                    :first_name => params[:first_name],
                    :last_name => params[:last_name],
                    :email => params[:email],
                    :age => params[:age],
                    :password => params[:password],
                    :password_confirmation => params[:password_confirmation],
                }
            }.to_json,
            :headers => {
                'Content-Type' => 'application/json'
            }
        }
        result = HTTParty.post(USERS_MS + "users", options)
        if result.code == 201
            render json: {
                message: "El usuario se creó correctamente",
                user: result["user"]
            }, status: :created
        else
            render json: {
                message: "Ocurrió un error al crear el usuario",
                errors: JSON.parse(result.body)
            }, status: :bad_request
        end
    end

    def updateUser
        options = {
            :body => params[:manage_user],
            :headers => {
                'Content-Type' => 'application/json',
                'Authorization' => request.headers["Authorization"]
            }
        }
        puts options
        result = HTTParty.put(USERS_MS + "users/" + params[:id], options)
        if result.code == 200
            render json: {
                message: "El usuario se creó correctamente",
                user: JSON.parse(result.body)
            }, status: :ok
        else
            render json: {
                message: "Ocurrió un error al modificar el usuario",
                errors: JSON.parse(result.body)
            }, status: :bad_request
        end
    end

    def searchUsers
         if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                old_token = current_user.header['jwt']
                 puts "old token: "
                 puts old_token
                options = {
                    :headers => {
                        'Accept' => 'application/json',
                        'Authorization' => old_token
                    }
                }
                sleep(1) #sleep a second
                result1 = HTTParty.get(USERS_MS + "search?q=" + params[:name], options)
                # puts current_user.header['jwt']
                # puts result1.header['jwt']
                new_token = result1.header['jwt']
                puts "new token: "
                puts new_token
                if result1.code == 200
                    render json: {
                        users: JSON.parse(result1.body),
                        token: new_token
                    }, status: :ok
                else
                    render json: {
                        message: "Ocurrió un error al obtener los usuarios",
                        errors: result1.body,
                        token: new_token
                    }, status: :bad_request
                end
             end
         else
             render json: {
                 message: "Necesita de un token para realizar las peticiones",
             }, status: :unauthorized
         end
    end

    def profile
        if request.headers.include? "Authorization"
            if current_user = checkToken(request.headers["Authorization"])
                render json: {
                    user: current_user["user"],
                    token: current_user.header['jwt']
                }, status: :ok
            end
        else
            render json: {
                message: "Necesita de un token para realizar las peticiones",
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
