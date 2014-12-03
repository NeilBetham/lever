module Handbrake
  def buildCommand(base_command, input_file, output_file)
    # Takes in base command with tokens %IF and %OF and build the final command with the tokens replaced
    base_command.gsub(/%IF|%OF/, '%IF' => input_file, '%OF' => output_file)
  end
end
