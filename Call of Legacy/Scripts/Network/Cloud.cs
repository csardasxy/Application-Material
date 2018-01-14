using UnityEngine;
using cn.bmob.api;
using cn.bmob.io;
using System.Collections;
using System.Collections.Generic;
using System.Net.NetworkInformation;

/*
该脚本请务必放置在GameController下
*/
public class Cloud : MonoBehaviour {

    private BmobUnity bmob;

    public static string ID = null;

    private int flag = 0;

	// Use this for initialization
	void Start () {
        bmob = GameObject.FindGameObjectWithTag("GameController").GetComponent<BmobUnity>();
        List<string> ids = GetMacByNetworkInterface();
        if (ids.Count>0 && GameUser.CurrentUser == null) {
            foreach(string id in ids) {
                FindUser(id);
            }
            StartCoroutine(checkLogin(ids));
        }
    }

    private IEnumerator checkLogin(List<string> ids) {
        while (flag < ids.Count && ID == null) {
            yield return 1;
        }
        if (ID == null) {
            GameUser user = new GameUser();
            user.username = ids[0];
            user.password = ids[0];
            bmob.Signup<GameUser>(user, (resp, ex) => {
                if (ex != null) {
                    print("注册失败, 失败原因为： " + ex.Message);
                    return;
                }
                ID = ids[0];
                print("注册成功, ID:" + ID);
                bmob.Login<GameUser>(ID, ID, (resp1, exception) =>
                {
                    if (exception != null) {
                        print("登录失败, 失败原因为： " + exception.Message);
                        return;
                    }
                    print("登录成功, ID:" + ID);
                    print("登录成功, 当前用户对象Session： " + BmobUser.CurrentUser.sessionToken);
                });
            });
        } else {
            bmob.Login<GameUser>(ID, ID, (resp, exception) =>
            {
                if (exception != null) {
                    print("登录失败, 失败原因为： " + exception.Message);
                    return;
                }
                print("登录成功, ID:" + ID);
                print("登录成功, 当前用户对象Session： " + BmobUser.CurrentUser.sessionToken);
            });
        }
    }

    public void FindUser(string id) {
        BmobQuery query = new BmobQuery();
        query.WhereEqualTo("username", id);
        bmob.Find<GameUser>(GameUser.TABLE, query, (resp, ex) => {
            if (ex != null) {
                print("查找失败, 失败原因为： " + ex.Message);
                flag++;
                return;
            }
            if (resp.results.Count > 0) {
                ID = id;
                print("存在用户:" + resp.results[0].username);
            }
            else
            {
                flag++;
            }
        });
    }

    public static List<string> GetMacByNetworkInterface() {
        List<string> macs = new List<string>();
        NetworkInterface[] interfaces = NetworkInterface.GetAllNetworkInterfaces();
        foreach (NetworkInterface ni in interfaces) {
            if (ni.GetPhysicalAddress().ToString() != "") {
                macs.Add(ni.GetPhysicalAddress().ToString());
            }
        }
        return macs;
    }

    public void PushDanmaku(string content, float x, float y, float z, int level, Color color, int fontSize = 14) {
        Danmaku danmaku = new Danmaku();
        danmaku.Content = content;
        danmaku.UserId = BmobUser.CurrentUser.username;
        danmaku.X = x;
        danmaku.Y = y;
        danmaku.Z = z;
        danmaku.Level = level;
        danmaku.FontSize = fontSize;
        danmaku.ColorR = new BmobDouble(color.r);
        danmaku.ColorG = new BmobDouble(color.g);
        danmaku.ColorB = new BmobDouble(color.b);
        bmob.Create(danmaku, (resp, exception) =>
        {
            if (exception != null) {
                print("保存失败, 失败原因为： " + exception.Message);
                return;
            }

            print("保存成功, @" + resp.createdAt);
        });
    }

    private float lastX, lastY, lastZ;
    private int lastLevel;

    public void PullDanmaku(int level,float x,float y,float z) {
        if(Mathf.Abs(x - lastX) <= DanmakuSystem.Offset && Mathf.Abs(y - lastY) <= DanmakuSystem.Offset && Mathf.Abs(z - lastZ) <= DanmakuSystem.Offset && level == lastLevel) {
            return;
        }
        lastX = x;
        lastY = y;
        lastZ = z;
        lastLevel = level;
        BmobQuery query = new BmobQuery();
        query.WhereEqualTo("Level", level);
        query.WhereGreaterThanOrEqualTo("X", x - DanmakuSystem.Offset);
        query.WhereLessThanOrEqualTo("X", x + DanmakuSystem.Offset);
        query.WhereGreaterThanOrEqualTo("Y", y - DanmakuSystem.Offset);
        query.WhereLessThanOrEqualTo("Y", y + DanmakuSystem.Offset);
        query.WhereGreaterThanOrEqualTo("Z", z - DanmakuSystem.Offset);
        query.WhereLessThanOrEqualTo("Z", z + DanmakuSystem.Offset);
        bmob.Find<Danmaku>("Danmaku", query, (resp, ex) => {
            if (ex != null) {
                print("查询失败, 失败原因为： " + ex.Message);
                return;
            }

            //对返回结果进行处理
            List<Danmaku> list = resp.results;
            foreach (Danmaku d in list) {
                if (!DanmakuSystem.idSet.Contains(d.objectId)) {
                    DanmakuSystem.danmakuQueue.Enqueue(d);
                    DanmakuSystem.idSet.Add(d.objectId);
                }
            }
        });
    }

    public void PushSave(string data) {
        GameUser user = BmobUser.CurrentUser as GameUser;
        if (user != null) {
            user.SaveData = data;
            user.Level = GameObject.FindGameObjectWithTag("GameController").GetComponent<GameController>().CurrentLevel;
            bmob.UpdateUser(user, (callbackData, ex) => {
                if (ex != null) {
                    print("保存失败, 失败原因为： " + ex.Message);
                    return;
                }
                print("保存成功, @" + callbackData.updatedAt);
            });
        }
    }

    public delegate void OnLoadSuccess(string data,int level);
    public void PullSave(OnLoadSuccess onLoadSuccess) {
        BmobQuery query = new BmobQuery();
        query.WhereEqualTo("username", GameUser.CurrentUser.username);
        bmob.Find<GameUser>(GameUser.TABLE, query, (resp, ex) => {
            if (ex != null) {
                print("载入失败, 失败原因为： " + ex.Message);
                return;
            }
            print("载入成功:" + resp.results[0].updatedAt);
            string resSaveData = resp.results[0].SaveData;
            int level = resp.results[0].Level == null ? 1 : resp.results[0].Level.Get();
            onLoadSuccess(resSaveData, level);
        });
    }
}
