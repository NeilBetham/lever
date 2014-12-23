module Handbrake
  def build_command(base_command, input_file, output_file)
    # Takes in base command with tokens %IF and %OF and build the final command with the tokens replaced
    base_command.gsub(/%IF|%OF/, '%IF' => input_file, '%OF' => output_file)
  end

  def get_encode_percent(data)
    unless /Encoding/ =~ data
      return nil
    end

    if /\d+\.\d+(?=\s%)/ =~ data
      return $~
    end
  end

  module_function :build_command, :get_encode_percent
end
