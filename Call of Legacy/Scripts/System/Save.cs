using UnityEngine;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System;

/// <summary>
/// This script controls saving action in the game
/// </summary>

public class Save {

    public static string LOCAL_DATA_PATH = @"/save.data";
    public static string LOCAL_LEVEL_PATH = @"/save.lv";
    public static Vector3 PlayerPosition = new Vector3(134.312f, -6f, 36f);

    public static bool saveLocal() {
        FileStream fs = null;
        BinaryWriter writer = null;
        try {
            byte[] data = save();
            fs = new FileStream(LOCAL_DATA_PATH, FileMode.Create, FileAccess.Write);
            fs.Write(data, 0, data.Length);
            writer = new BinaryWriter(new FileStream(LOCAL_LEVEL_PATH, FileMode.Create, FileAccess.Write));
            writer.Write(GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().CurrentLevel);
            return true;
        } catch {
            return false;
        } finally {
            if (fs != null)
                fs.Close();
            if (writer != null)
                writer.Close();
        }

    }

    public static bool loadLocal() {
        BinaryReader reader = null;
        try {
            reader = new BinaryReader(new FileStream(LOCAL_LEVEL_PATH, FileMode.Open, FileAccess.Read));
            GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().CurrentLevel = reader.ReadInt32();
        } catch(Exception e) {
            Debug.Log(e.Message);
            GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().CurrentLevel = 1;
            return false;
        } finally {
            if (reader != null)
                reader.Close();
        }

        FileStream fs = null;
        try {
            fs = new FileStream(LOCAL_DATA_PATH, FileMode.Open, FileAccess.Read);
            MemoryStream ms = new MemoryStream();
            byte[] buffer = new byte[512];
            int len = 0;
            while ((len = fs.Read(buffer, 0, buffer.Length)) > 0) {
                ms.Write(buffer, 0, len);
            }
            load(ms.GetBuffer());
            GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().SceneLoadComplete = true;
            return true;
        } catch(Exception e) {
            Debug.Log(e.Message);
            return false;
        } finally {
            if(fs!=null)
                fs.Close();
        }

    }

    public static bool saveCloud() {
        if (GameUser.CurrentUser == null) {
            return false;
        }
        string data = Convert.ToBase64String(save());
        Cloud cloud = GameObject.FindGameObjectWithTag("GameController").GetComponent<Cloud>();
        cloud.PushSave(data);
        return true;
    }

    public static bool loadCloud() {
        Cloud cloud = GameObject.FindGameObjectWithTag("GameController").GetComponent<Cloud>();
        try {
            if (GameUser.CurrentUser == null) {
                return false;
            }
            cloud.PullSave((data,level) => {
                if (data == null) {
                    GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().SceneLoadComplete = true;
                    return;
                }
                load(Convert.FromBase64String(data));
                GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().CurrentLevel = level;
                GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().SceneLoadComplete = true;
            });
            return true;
        } catch {
            return false;
        }
    }

    private static byte[] save() {
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        GameObject camera = GameObject.FindGameObjectWithTag("MainCamera");

        Dictionary<string, object> dictionary = new Dictionary<string, object>();

        dictionary.Add("MonumentSystem.Graves", MonumentSystem.Graves);
        dictionary.Add("MonumentSystem.Bodys", MonumentSystem.Bodys);
        dictionary.Add("BodyInfo.IDCount", BodyInfo.IDCount);
        dictionary.Add("Player.Transform.Position.X", player.transform.position.x);
        dictionary.Add("Player.Transform.Position.Y", player.transform.position.y);
        dictionary.Add("Player.Transform.Position.Z", player.transform.position.z);

        MemoryStream ms = new MemoryStream();
        BinaryFormatter bf = new BinaryFormatter();
        bf.Serialize(ms, dictionary);
        return ms.GetBuffer();
    }

    private static void load(byte[] data) {
        GameObject player = GameObject.FindGameObjectWithTag("Player");
        GameObject camera = GameObject.FindGameObjectWithTag("MainCamera");

        BinaryFormatter bf = new BinaryFormatter();
        MemoryStream ms = new MemoryStream(data);
        Dictionary<string, object> dictionary = bf.Deserialize(ms) as Dictionary<string, object>;

        PlayerPosition = new Vector3((float)dictionary["Player.Transform.Position.X"], (float)dictionary["Player.Transform.Position.Y"], (float)dictionary["Player.Transform.Position.Z"]);
        MonumentSystem.Graves = dictionary["MonumentSystem.Graves"] as Stack<GraveInfo>;
        if (MonumentSystem.Graves == null)
            MonumentSystem.Graves = new Stack<GraveInfo>();
        MonumentSystem.Bodys = dictionary["MonumentSystem.Bodys"] as List<BodyInfo>;
        if (MonumentSystem.Bodys == null)
            MonumentSystem.Bodys = new List<BodyInfo>();
        BodyInfo.IDCount = (int)dictionary["BodyInfo.IDCount"];
    }
}
