Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {} // ����Ƽ�� �������̽��κ��� �Է¹޴� �������� '_BumpMap' �̶�� ������, �ؽ��� �������̽��� �븻���� ���� ���̶�� ������.
        _SpecCol ("Specular Color", Color) = (1, 1, 1, 1) // ����ŧ���� ������ �������̽��� �ޱ� ���� ������Ƽ �߰�
        _SpecPow ("Specular Power", Range(10, 200)) = 100 // ����ŧ���� ����(�ŵ�����. �������� ����ŧ�� ������ ������)�� �������̽��� �ޱ� ���� ������Ƽ �߰�
        _SpecCol2 ("Specular Color2", Color) = (0.7, 0.7, 0.7, 1) // ��¥ ����ŧ���� ������ �������̽��� �ޱ� ���� ������Ƽ �߰�
        _SpecPow2("Specular Power2", Range(10, 200)) = 50 // ��¥ ����ŧ���� ����(�ŵ�����. �������� ����ŧ�� ������ ������)�� �������̽��� �ޱ� ���� ������Ƽ �߰�
        _GlossTex ("Gloss Tex", 2D) = "white" {} // �������� ����ŧ�� ������ �ٸ��� �������ֱ� ���� �ʿ��� Spec �ؽ��ĸ� �������̽��� �ޱ� ���� ������Ƽ �߰�

        _RimCol("Rim Color", Color) = (0.5, 0.5, 0.5, 1) // �������� ������ �������̽��� �ޱ� ���� ������Ƽ �߰�
        _RimPow("Rim Power", Range(1, 10)) = 6 // �������� �β�(����?, ���� �������� �о���)�� �������̽��� �ޱ� ���� ������Ƽ �߰�
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        // Test ��� �̸��� Ŀ���� ������ ����
        #pragma surface surf Test // noambient // ȯ�汤 ���� ����

        sampler2D _MainTex;
        sampler2D _BumpMap;
        sampler2D _GlossTex;
        float4 _SpecCol;
        float _SpecPow;
        float4 _SpecCol2;
        float _SpecPow2;

        float4 _RimCol;
        float _RimPow;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_BumpMap;
            float2 uv_GlossTex;
        };

        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            float4 m = tex2D(_GlossTex, IN.uv_GlossTex); // ����ŧ�� ���� ������ ���� �޾ƿ� �ؽ���(���翡���� GlossMap �� ���������, ���⼭�� Spec ���� ����Ұ���. ���İ��� grayScale �� �����ϱ� ������ �� �̰Ŷ�...)
            o.Albedo = c.rgb;

            // UnpackNormal() �Լ��� ��ȯ�� �븻�� �ؽ��� ������ DXTnm ���� ���ø��ؿ� �ؼ��� float4�� ���ڷ� �޾� float3 �� ��������.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));

            /*
                ����ŧ�� ���� ������ ���� �޾ƿ� Spec �ؽ��Ĵ� jpg �̹Ƿ� ����ä���� �������� ����. 
                ���� ����Ƽ���� Alpha Source �� 'From Gray Scale' �� �����ؼ� ����ä���� ���� �������. 
                �� ���� ������� ����ä���� o.Gloss ����ü �Ӽ����� �־��� ��.

                o.Gloss ������Ƽ�� ���� ������ Specular �� ����(?) �� ǥ���� ������,
                ������ Specular �� opacity ���� �����̶�� ���� ��.

                �ش� ������ p.253 �� ��������.
            */
            o.Gloss = m.a;
            o.Alpha = c.a;
        }

        // Test ��� �̸��� Ŀ���� ������ �Լ� �ۼ�
        float4 LightingTest(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten) { // ī�޶� ���Ͱ� �ʿ��� ���, Ŀ���� ������ �Լ��� ���ڸ� 4�� �����ϰ�, �� ��° ���ڸ� viewDir �� �������� �ϸ� ��. (������ �ݵ�� ���Ѿ� ��.)
            float4 final; // ���� ������ ��Ƽ� �������� ����

            // Lambert term (����Ʈ(��ǻ��) ������ ��� ����)
            // surf ���� Unpack ���� �븻���� �����͸� �����Ͽ� ��Ⱚ�� ����.
            // �̶�, ������ -1 ~ 1 ������ ���� �����ϹǷ�, �������� �����ϸ� �ٸ� �����̳� ���� �߰����൵ ��� ��ο� �������� ����.
            // �̸� �ذ��ϱ� ���� saturate() �����Լ��� 0 �̸��� �������� �� �߶� 0���� ���� ��ȯ��Ű�� ��.
            float ndotl = saturate(dot(s.Normal, lightDir)); 
            float3 DiffColor; // ��ǻ���÷�, �� ����Ʈ(����Ʈ �������� �ٸ� ���� ��ǻ�� �������̶�� ��.) ���� ������ ����� �÷����� ���� ������ ������.
            DiffColor = ndotl * s.Albedo * _LightColor0.rgb * atten;  // Albedo �ؽ��� ����, ���� ���� �� ����(_LightColor ���庯��), ����(atten) �� ��� ������ ����Ʈ(��ǻ��) �÷�

            // Spec term (blinn-phong ����ŧ�� ��Ⱚ ��� ����)
             // �� �ݻ� �𵨿��� ����ŧ���� ���ϴ� ������ ����ȭ�� '��-�� ����'���� ����ŧ�� ���
            float3 SpecColor;
            float3 H = normalize(lightDir + viewDir); // �켱 ī�޶��Ϳ� �������� ���ݺ��͸� ���� ��, ���̸� 1�� ����. (p.354 ����)
            float spec = saturate(dot(H, s.Normal)); // �������� ����ŧ�� ����. �������Ϳ� �븻���͸� ������. -> ������ -1 ~ 1 ���̴ϱ� saturate() �� �������� 0���� �ʱ�ȭ��.
            spec = pow(spec, _SpecPow); // �ٵ� ���� ó�� ������ spec ���� �״�� �����ϸ�, ����ŧ�� ������ �ʹ� �о �˴� ������� ����. -> �׷��� �̰Ÿ� 100�ŵ����� ���༭, Ư�� �������� Ȯ ��������� �� ��. (p.330 ����)
            // SpecColor = spec * _SpecCol.rgb; // spec ���� float �Ѱ��ϱ�, �������̽��� �޾ƿ� ����ŧ�� ������ _SpecCol.rgb �� ���������ν�, �ش� ����ŧ���� ��ŭ�� ��Ⱚ�� ���� ������ ����� �� ����.
            SpecColor = spec * _SpecCol.rgb * s.Gloss; // ����ŧ���� ����, opacity�� �ش��ϴ� ����ü s.Gloss ���� ���������ν�, ������ ����ŧ�� ������ ������.

            // Rim term (Rim ����Ʈ, �� Fresnel ��� ����)
            // ���� surf �Լ����� Input ����ü�κ��� �������� ���ؽ� -> ī�޶� ������ viewDir �� Ŀ���Ҷ����� �Լ������� ������ �� �ְ� �Ǿ����Ƿ�,
            // ������ �� �ְ� �� �迡 �����ڵ� �����ؼ� ���� ���󰪿� ���ؼ� �����غ��ڴ� ��.
            float3 rimColor; // ���� ������ ���� ������� ������ ����
            float rim = abs(dot(viewDir, s.Normal)); // �� ���Ϳ� �븻���� �븻���͸� ������ ��, ������������� ������ �����ϱ� ���� abs() �� �����. 
            float invrim = 1 - rim; // rim�� ��ü�� ī�޶�� ���ϴ� ���ϼ��� ���, �����ڸ��ϼ��� ��ο�Ƿ�, 1���� ���༭ �������� �������༭, �����ڸ��� ������ ���� ���� �������� ��.
            rimColor = pow(invrim, _RimPow) * _RimCol.rgb; // �������� �β��� ������ �����ϱ� ���� �ŵ����� ó�� �� Ư�� ����(���⼭�� ȸ������?)�� ������.

            // Fake Spec term (Fresnel ������ �λ깰�� rim ���� �̿��� ��¥ ����ŧ�� ��� ����)
            float3 SpecColor2; // ��¥ ����ŧ���� ����ؼ� ������ ����
            SpecColor2 = pow(rim, _SpecPow2) * _SpecCol2.rgb * s.Gloss; // SpecColor�� ���������� �ŵ�����ó��, ����ŧ�� ���� ����(���⼭�� ���� ȸ��), s.Gloss ������ ����ŧ�� ����(opacity) ����

            // Final term (���� ���� ��� ����)
            // final.rgb = DiffColor.rgb + SpecColor.rgb; // ����Ʈ ������ ����� ��-�� ����ŧ�� ������ ���ؼ� ���� ������ ������. -> �� �ݻ� �𵨿����� �ں��Ʈ �÷� + ��ǻ�� + ����ŧ�� �̷� ������ �� ������ ���� ���ؼ� ����߾���? (WebGL å ����)
            // final.rgb = DiffColor.rgb + SpecColor.rgb + rimColor.rgb; // ������ ���갪�� ���� ���� ������.
            final.rgb = DiffColor.rgb + SpecColor.rgb + rimColor.rgb + SpecColor2.rgb; // ��¥ ����ŧ�� ���� ���� ���� ������. (���� ���󿡼��� ������ ���� �� �ִ� ��찡 �����Ƿ�, �̷� ������ rim���� �̿��� ��¥ ����ŧ���� �߰����ִ� �� �������� �츮�� ���� �����ϴ� ����̶�� ��.)
            final.a = s.Alpha;

            // ���� ���������� rim�� 200 �����ؼ� �������ָ�, ī�޶� �ü��� ���� ���̶���Ʈ ������ �����̴� �� �� �� ����.
            // ��, '���������� ���� rim�� == ����ŧ��' ��� �� �� �ִ� ������! 
            // Fresnel ������ �λ깰�� �Ұ��� rim���� ��ǻ� ����ŧ���� ������ ����� ����� ���� ����.
            // ����, �긦 �׳� spec �� ��� ����ص� ������!
            // return pow(rim, 200); 

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
