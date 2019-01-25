#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require "spec_helper"

describe Messages::AssignmentSubmittedLate::SummaryPresenter do
  let(:course) { course_model(name: "MATH-101") }
  let(:assignment) { course.assignments.create!(name: "Introductions", due_at: 1.day.ago) }
  let(:teacher) { course_with_teacher(course: course, active_all: true).user }

  let(:student) do
    course_with_user("StudentEnrollment", course: course, name: "Adam Jones", active_all: true).user
  end
  let(:submission) { assignment.submit_homework(student) }

  describe "Presenter instance" do
    let(:message) { Message.new(context: submission, user: teacher) }
    let(:presenter) { Messages::AssignmentSubmittedLate::SummaryPresenter.new(message) }

    it "#link is a url for the submission when the assignment is not anonymously graded" do
      expect(presenter.link).to eql(
        message.course_assignment_submission_url(course, assignment, submission.user_id)
      )
    end

    context "when the assignment is anonymously graded" do
      before(:each) do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#link is a url to SpeedGrader" do
          expect(presenter.link).to start_with(
            message.speed_grader_course_gradebook_url(course, assignment_id: assignment.id)
          )
        end

        it "#link includes the anonymous id for the student" do
          expect(presenter.link).to end_with("\#{\"anonymous_id\":\"#{submission.anonymous_id}\"}")
        end
      end

      it "#link is a url for the submission when grades have been posted" do
        assignment.unmute!
        expect(presenter.link).to eql(
          message.course_assignment_submission_url(course, assignment, submission.user_id)
        )
      end
    end
  end

  describe "generated message" do
    let(:message) { generate_message(:assignment_submitted_late, :summary, submission, {}) }
    let(:presenter) do
      msg = Message.new(context: submission, user: teacher)
      Messages::AssignmentSubmittedLate::SummaryPresenter.new(msg)
    end

    it "#url is a url for the submission when the assignment is not anonymously graded" do
      expect(message.url).to eql(
        message.course_assignment_submission_url(course, assignment, submission.user_id)
      )
    end

    context "when the assignment is anonymously graded" do
      context "when grades have not been posted" do
        it "#url is a url to SpeedGrader" do
          assignment.update!(anonymous_grading: true)
          expect(message.url).to start_with(
            message.speed_grader_course_gradebook_url(course, assignment_id: assignment.id)
          )
        end

        it "#url includes the anonymous id for the student" do
          assignment.update!(anonymous_grading: true)
          expect(message.url).to end_with("\#{\"anonymous_id\":\"#{submission.anonymous_id}\"}")
        end
      end

      it "#url is a url for the submission when grades have been posted" do
        assignment.unmute!
        expect(message.url).to eql(
          message.course_assignment_submission_url(course, assignment, submission.user_id)
        )
      end
    end
  end
end