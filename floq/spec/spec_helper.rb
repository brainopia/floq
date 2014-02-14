require 'floq'

Floq::Provider.default
  .use!(:adapter, :memory)
  .use!(:logger, StringIO.new)
  .reset!(:rescuer)
