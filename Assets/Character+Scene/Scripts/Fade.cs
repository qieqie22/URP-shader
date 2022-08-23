using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fade : MonoBehaviour
{
    float tempTime;
    // Start is called before the first frame update
    void Start()
    {
        tempTime = 0;
    }

    // Update is called once per frame
    void Update()
    {
        if (Time.time > 19)
        {
            transform.position = new Vector3(0, -10, 0);
        }
    }
}
