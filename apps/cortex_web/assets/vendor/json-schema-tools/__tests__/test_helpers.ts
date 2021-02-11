/**
 * Test Helpers
 * ===========================================================================
 *
 * Yeah um this stuff helps you with your tests.
 */

import FS from "fs";
import Path from "path";
import Net from "net";
import Process from "process";


export const PATHS: Record<string, string> = {};
PATHS.REPO = Path.resolve(__dirname, "..");
PATHS.LOG = Path.resolve(PATHS.REPO, "log", "tests.log");

// let _socket: null | Net.Socket = null;
// let _streamTransport: null | Winston.transports.StreamTransportInstance = null;

function puts(msg: string) {
  Process.stderr.write("### " + msg + " ###\n");
}

// export function setupLogging(): Promise<void> {
//   return new Promise((resolve, _reject) => {
//     _socket = Net.createConnection(
//       {
//         path: PATHS.LOG,
//       },
//       () => {
//         if (_socket) {
//           _socket.on("error", (err) => {
//             puts(`ERROR [socket] ${err}`);
//           });
//         }
        
//         const stream = FS.createWriteStream(PATHS.LOG, {
//           fd: (_socket as any)._handle.fd,
//           autoClose: false,
//         });
        
//         stream.on("error", (err) => {
//           puts(`ERROR [stream] ${err}`);
//         });

//         _streamTransport = new Winston.transports.Stream({
//           level: "debug",
//           stream,
//           format: Winston.format.combine(
//             Winston.format.colorize(),
//             Winston.format.simple()
//           ),
//         });

//         _streamTransport.on("error", (err) => {
//           puts(`ERROR [transport] ${err}`);
//         });

//         Winston.add(_streamTransport);

//         resolve();
//       }
//     );
//   });
// }

// export async function teardownLogging(): Promise<void> {
//   puts("Tearing DOWN!");

//   // await new Promise<void>((resolve, _reject) => {
//   //   if (_streamTransport !== null) {
//   //     puts("Waiting for stream transport to finish...");
//   //     _streamTransport.on("finish", () => {
//   //       puts("Stream transport finished.");
//   //       if (_streamTransport) {
//   //         Winston.remove(_streamTransport);
//   //       }
//   //       resolve();
//   //     });

//   //     _streamTransport.end();
//   //   }
//   // });

//   await new Promise<void>((resolve, _reject) => {
//     if (_socket !== null && _socket.writable) {
//       puts("Ending client...");
//       _socket.end(() => {
//         puts("Client ended.");
//         resolve();
//       });
//     } else {
//       resolve();
//     }
//   });
// }
