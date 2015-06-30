class InboxController < ApplicationController

	def destroy
    Inbox.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
end
