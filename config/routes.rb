GeminiSqlChat::Engine.routes.draw do
  get '/', to: 'chat#index'
  post '/query', to: 'chat#query'
  get '/conversations', to: 'chat#conversations'
  get '/conversations/:id', to: 'chat#load_conversation'
  post '/conversations/new', to: 'chat#new_conversation'
  delete '/conversations/:id', to: 'chat#delete_conversation'
  
  get '/scheduled_tasks', to: 'chat#scheduled_tasks'
  delete '/scheduled_tasks/:id', to: 'chat#delete_scheduled_task'
end
