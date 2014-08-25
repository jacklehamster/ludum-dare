using System;
using System.Collections.Generic;
using System.Text;
using System.Collections;
using PlayerIO.GameLibrary;
using System.Drawing;

namespace Dobukiland
{
	public class Player : BasePlayer {
	}

    [RoomType("Dobukiland")]
	public class GameCode : Game<Player> {

        Dictionary<string, HashSet<Player>> dataListeners;
        HashSet<string> inProgress;


		public override void GameStarted() {
            dataListeners = new Dictionary<string, HashSet<Player>>();
            inProgress = new HashSet<string>();
        }

        public override void UserLeft(Player player)
        {
            base.UserLeft(player);
            foreach (HashSet<Player> playerList in dataListeners.Values)
            {
                playerList.Remove(player);
            }
        }

        private void saveImage(String id, byte[] bytes)
        {
            inProgress.Add(id);
            //Create object in table Users with ConnectUserId as key
            PlayerIO.BigDB.LoadOrCreate("Images", id,
               delegate(DatabaseObject result)
               {
                   if(!result.Contains("id"))
                       result.Set("id", id);
                   result.Set("data", bytes);
                   result.Save();

                   broadcastImage(id, bytes);
                   inProgress.Remove(id);
               });
        }

        private void broadcastImage(string id,byte[] bytes)
        {
            if (dataListeners.ContainsKey(id))
            {
                HashSet<Player> playerList = dataListeners[id];
                foreach (Player player in playerList)
                {
                    player.Send("receiveBinary",id, bytes);
                }
                dataListeners.Remove(id);
            }
        }

        private void loadImage(string id)
        {
            inProgress.Add(id);
            PlayerIO.BigDB.Load("Images", id,
                delegate(DatabaseObject result)
                {
                    if (result != null && result.Contains("data"))
                    {
                        Broadcast(id, result.GetBytes("data"));
                    }
                    inProgress.Remove(id);
                });
        }

        private void loadImage(string id, Player player)
        {
            if (!dataListeners.ContainsKey(id))
            {
                dataListeners[id] = new HashSet<Player>();
            }
            HashSet<Player> playerList = dataListeners[id];
            playerList.Add(player);
            if (!inProgress.Contains(id))
            {
                loadImage(id);
            }
            
        }

        // This method is called when a player sends a message into the server code
        public override void GotMessage(Player player, Message message)
        {
            base.GotMessage(player, message);
			switch(message.Type) {
                case "saveBinary":
                    saveImage(message.GetString(0), message.GetByteArray(1));;
                    break;
                case "loadBinary":
                    loadImage(message.GetString(0), player);
                    break;
                default:
                    Console.WriteLine("Received message:",message.Type);
                    Broadcast(message);
                    break;
			}
		}
	}
}
