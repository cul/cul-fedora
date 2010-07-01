class ReportController < ApplicationController

  def by_collection
    @report = Report.generate(:by_collection)


    @collections = @report[:collections]
    @formats = @report[:formats]
  end

  private

end
