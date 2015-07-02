class ExporterController < ApplicationController
  unloadable


  def export
  	@resp = ['Blast of the universe!']
  	@timeEntries = TimeEntry.all
  end
end
