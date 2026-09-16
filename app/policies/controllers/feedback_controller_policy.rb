# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Public, unauthenticated controller (mirrors Controllers::FormControllerPolicy).
# Actual access control happens inside FeedbackController via Token validation,
# not here -- this just tells Zammad's Pundit integration that no logged-in
# user is required to reach these actions at all.
class Controllers::FeedbackControllerPolicy < Controllers::ApplicationControllerPolicy
  USER_REQUIRED = false

  def show?
    true
  end

  def submit?
    true
  end
end
