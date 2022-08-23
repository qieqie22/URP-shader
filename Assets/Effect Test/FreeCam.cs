using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum CameraaMode
{
    FULLBODY,
    FACE,
    FREE
}
public class FreeCam : MonoBehaviour
{
    private Transform cameraTransform;

    private CameraaMode cameraMode = CameraaMode.FREE;

    private float camSpeed = 1.53f;  //camera move speed
    private float adjustSpeed = 0.5f;  //wheel click move speed
    private float rotateSpeed = 5f;    //rotation speed
    private float enlargeSpeed = 2f;    //wheel roll speed
    private float moveDis = 5f;   //wheel max move distance
    private float adjustMove = 0.2f; //wheel click control

    private float rotateX = 180f;
    private float rotateY = 15.321f;

    void Start()
    {
        cameraTransform = transform;
    }
    void Update()
    {
        if (Input.GetKeyUp(KeyCode.Space))
        {
            CameraReset();
        }

        if (cameraMode == CameraaMode.FREE)
        {
            CameraMove();
            CameraEnlarge();
            CameraRotate();
            CameraAdjust();
        }
        SwitchCameraMode();


    }
    private void SwitchCameraMode()
    {
        switch (cameraMode)
        {
            case CameraaMode.FULLBODY:
                cameraTransform.localRotation = Quaternion.Euler(15.321f, 180f, 0f);
                cameraTransform.position = new Vector3(0f, 1.421f, 1.67f);
                break;
            case CameraaMode.FACE:
                cameraTransform.localRotation = Quaternion.Euler(0.631f, 180f, 0f);
                cameraTransform.position = new Vector3(0f, 1.408f, 0.597f);
                break;
            default:
                break;
        }
    }
    void CameraMove()
    {
        if (Input.GetKey(KeyCode.W))
        {
            cameraTransform.Translate(Vector3.forward * Time.deltaTime * camSpeed);
        }
        if (Input.GetKey(KeyCode.S))
        {
            cameraTransform.Translate(Vector3.back * Time.deltaTime * camSpeed);
        }
        if (Input.GetKey(KeyCode.A))
        {
            cameraTransform.Translate(Vector3.left * Time.deltaTime * camSpeed);
        }
        if (Input.GetKey(KeyCode.D))
        {
            cameraTransform.Translate(Vector3.right * Time.deltaTime * camSpeed);
        }
        if (Input.GetKey(KeyCode.Q))
        {
            cameraTransform.Translate(Vector3.up * Time.deltaTime * camSpeed);
        }
        if (Input.GetKey(KeyCode.E))
        {
            cameraTransform.Translate(Vector3.down * Time.deltaTime * camSpeed);
        }

    }
    void CameraEnlarge()
    {
        if (Input.GetAxis("Mouse ScrollWheel") != 0)
        {
            float tempDis = Input.GetAxis("Mouse ScrollWheel") * enlargeSpeed;
            Vector3 tempPos = cameraTransform.localPosition + cameraTransform.forward * tempDis;
            if (tempPos.magnitude >= moveDis) return;
            cameraTransform.localPosition = tempPos;
        }
    }
    void CameraRotate()
    {
        if (Input.GetMouseButton(1))
        {
            rotateX = cameraTransform.eulerAngles.y + Input.GetAxis("Mouse X") * rotateSpeed;
            rotateY = cameraTransform.eulerAngles.x - Input.GetAxis("Mouse Y") * rotateSpeed;

            rotateX = ClampCamera(rotateX, -360, 360);
            rotateY = ClampCamera(rotateY, -360, 360);

            cameraTransform.localRotation = Quaternion.Euler(rotateY, rotateX, 0);
        }

    }
    void CameraAdjust()
    {
        if (Input.GetMouseButton(2))
        {
            float tempX = Input.GetAxis("Mouse X");
            float tempY = Input.GetAxis("Mouse Y");
            Vector3 YpZ = cameraTransform.up + cameraTransform.forward;
            YpZ.y = 0;
            Vector3 movePos = cameraTransform.position;
            movePos -= (transform.right * tempX + YpZ * tempY) * adjustSpeed;
            cameraTransform.position = Vector3.Lerp(cameraTransform.position, movePos, adjustMove);
        }
    }
    public void CameraReset()
    {
        cameraTransform.localPosition = new Vector3(0f, 1.421f, 1.67f);
        cameraTransform.localRotation = Quaternion.Euler(15.321f, 180f, 0f);
    }
    float ClampCamera(float cameraAngle, float minAngle, float maxAgnle)
    {
        if (cameraAngle <= -360)
            cameraAngle += 360;
        if (cameraAngle >= 360)
            cameraAngle -= 360;

        return Mathf.Clamp(cameraAngle, minAngle, maxAgnle);
    }

}
