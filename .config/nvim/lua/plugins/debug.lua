-- Debugging. rustaceanvim wires its own adapter (:RustLsp debuggables) using
-- codelldb from mason; C/C++ is configured here, Python via nvim-dap-python.
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "DAP continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "DAP step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "DAP step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "DAP step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>dB", function()
          require("dap").set_breakpoint(vim.fn.input("Condition: "))
        end, desc = "Conditional breakpoint" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

      local mason = vim.fn.stdpath("data") .. "/mason/packages"

      -- C / C++ / Rust via codelldb
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = mason .. "/codelldb/extension/adapter/codelldb",
          args = { "--port", "${port}" },
        },
      }
      local lldb_launch = {
        {
          name = "Launch executable",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = lldb_launch
      dap.configurations.cpp = lldb_launch

      -- Python via debugpy from mason
      require("dap-python").setup(mason .. "/debugpy/venv/bin/python")

      -- JS / TS via js-debug-adapter
      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { mason .. "/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
        },
      }
      for _, ft in ipairs({ "javascript", "typescript" }) do
        dap.configurations[ft] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
        }
      end
    end,
  },
}
