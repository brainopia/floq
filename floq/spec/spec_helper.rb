require 'floq'

Floq::Provider.default
  .use!(:storage, :memory)
  .use!(:logger, StringIO.new)
  .reset!(:rescuer)
