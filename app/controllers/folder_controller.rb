class FolderController < ApplicationController
  unloadable

  before_filter :require_staff

  include Blacklight::SolrHelper

  # fetch the documents that match the ids in the folder
  def index
    @response, @documents = get_solr_response_for_field_values("id",session[:folder_document_ids] || [])
  end

  # add a document_id to the folder
  def create
    unless session.has_key? :folder_document_ids
      puts "adding folder to session"
      session[:folder_document_ids] = []
    end
    puts "adding #{params[:id]} to folder"
    session[:folder_document_ids].push params[:id] 
    redirect_to :back
  end
 
  # remove a document_id from the folder
  def destroy
    puts "removing #{params[:id]} to folder"
    session[:folder_document_ids].delete(params[:id])
    redirect_to :back
  end
 
  # get rid of the items in the folder
  def clear
    session[:folder_document_ids] = []
    redirect_to folder_index_path
  end
 
end
