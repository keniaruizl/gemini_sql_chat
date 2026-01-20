module GeminiSqlChat
  class ScheduledTaskJob < ApplicationJob
    queue_as :default

    def perform(task_id)
      task = ScheduledTask.find_by(id: task_id)
      return unless task&.active?

      task.execute!
    end
  end
end
