Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {} // ����Ƽ�� �������̽��κ��� �Է¹޴� �������� '_BumpMap' �̶�� ������, �ؽ��� �������̽��� �븻���� ���� ���̶�� ������.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        // Test ��� �̸��� Ŀ���� ������ ����
        #pragma surface surf Test noambient // ȯ�汤 ���� ����

        sampler2D _MainTex;
    sampler2D _BumpMap;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;

            // UnpackNormal() �Լ��� ��ȯ�� �븻�� �ؽ��� ������ DXTnm ���� ���ø��ؿ� �ؼ��� float4�� ���ڷ� �޾� float3 �� ��������.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            o.Alpha = c.a;
        }

        // Test ��� �̸��� Ŀ���� ������ �Լ� �ۼ�
        float4 LightingTest(SurfaceOutput s, float3 lightDir, float atten) {
            float4 final; // ���� ������ ��Ƽ� �������� ����

            // surf ���� Unpack ���� �븻���� �����͸� �����Ͽ� ��Ⱚ�� ����.
            // �̶�, ������ -1 ~ 1 ������ ���� �����ϹǷ�, �������� �����ϸ� �ٸ� �����̳� ���� �߰����൵ ��� ��ο� �������� ����.
            // �̸� �ذ��ϱ� ���� saturate() �����Լ��� 0 �̸��� �������� �� �߶� 0���� ���� ��ȯ��Ű�� ��.
            float ndotl = saturate(dot(s.Normal, lightDir)); 
            float3 DiffColor; // ��ǻ���÷�, �� ����Ʈ(����Ʈ �������� �ٸ� ���� ��ǻ�� �������̶�� ��.) ���� ������ ����� �÷����� ���� ������ ������.
            DiffColor = ndotl * s.Albedo * _LightColor0.rgb * atten;  // Albedo �ؽ��� ����, ���� ���� �� ����(_LightColor ���庯��), ����(atten) �� ��� ������ ����Ʈ(��ǻ��) �÷�

            final.rgb = DiffColor.rgb;
            final.a = s.Alpha;

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
