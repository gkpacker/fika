defmodule Fika.Cli do
  use Bakeware.Script

  require Logger

  @impl Bakeware.Script
  def main(args) do
    parse_args(args)
  end

  defp parse_args([]) do
    IO.puts("""
    Usage:
      fika start <directory>
        Starts the router.fi file inside <directory>.

      fika exec [<filename> [--function <function_call>]]
        Executes the function call <function_call> inside the module defined in <filename>.

        Options:
          <filename>: defines the file to be compiled. Defaults to 'main.fi'
          -f | --function: chooses the function call to be run. Defaults to 'start()'
    """)
  end

  defp parse_args(["exec" | rest]) do
    options = [
      strict: [function: :string],
      aliases: [f: :function]
    ]

    {opts, rest} = OptionParser.parse!(rest, options)

    main_file = List.first(rest) || "main.fi"
    function = opts[:function] || "start()"

    unless File.exists?(main_file) do
      IO.puts("File #{main_file} not found.")
      System.halt(1)
    end

    {:module, module} = Fika.Code.load_file(main_file)

    fn_not_found_msg = "Function #{function} not found."

    try do
      Logger.debug("Calling :#{module}.#{function}")
      {result, _binding} = Code.eval_string(~s':"#{module}".#{function}')
      IO.inspect(result)
    rescue
      UndefinedFunctionError ->
        IO.puts(fn_not_found_msg)
        System.halt(2)
    end
  end

  defp parse_args(["start" | rest]) do
    path = List.first(rest)

    if path do
      File.cd!(path)
    end

    if not File.exists?("router.fi") do
      raise "cannot start webserver: file 'router.fi' not found in directory '#{path}'"
    end

    {:ok, _} = Fika.Router.start(nil, nil)

    IO.puts("Press Ctrl+C to exit")
    :timer.sleep(:infinity)
  end
end
