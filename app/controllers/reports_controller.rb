class ReportsController < ApplicationController
  before_filter :require_admin

  def preview
    @category = params[:category]
    @report = Report.generate(@category)
    @new_report = Report.new(:category => @category, :user => current_user, :generated_on => Date.today)


  end

  def index
    @reports = Report.all
  end
  
  def show
    @report = Report.find(params[:id])
  end
  
  def new
    @report = Report.new
  end
  
  def create
    @report = Report.new(params[:report])
  
    if @report.generate!.save
      flash[:notice] = "Successfully created report."
      redirect_to @report
    else
      render :action => 'new'
    end
  end
  
  def edit
    @report = Report.find(params[:id])
  end
  
  def update
    @report = Report.find(params[:id])
    if @report.update_attributes(params[:report])
      flash[:notice] = "Successfully updated report."
      redirect_to @report
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @report = Report.find(params[:id])
    @report.destroy
    flash[:notice] = "Successfully destroyed report."
    redirect_to reports_url
  end
end
