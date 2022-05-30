Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {} // 유니티는 인터페이스로부터 입력받는 변수명을 '_BumpMap' 이라고 지으면, 텍스쳐 인터페이스는 노말맵을 넣을 것이라고 인지함.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        // Test 라는 이름의 커스텀 라이팅 구현
        #pragma surface surf Test noambient // 환경광 영향 제거

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

            // UnpackNormal() 함수는 변환된 노말맵 텍스쳐 형식인 DXTnm 에서 샘플링해온 텍셀값 float4를 인자로 받아 float3 를 리턴해줌.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
            o.Alpha = c.a;
        }

        // Test 라는 이름의 커스텀 라이팅 함수 작성
        float4 LightingTest(SurfaceOutput s, float3 lightDir, float atten) {
            float4 final; // 최종 색상값을 담아서 리턴해줄 변수

            // surf 에서 Unpack 해준 노말값과 조명벡터를 내적하여 밝기값을 구함.
            // 이때, 내적은 -1 ~ 1 사이의 값을 포함하므로, 음수값이 존재하면 다른 조명값이나 색상 추가해줘도 계속 어두운 색상으로 찍힘.
            // 이를 해결하기 위해 saturate() 내장함수로 0 미만의 음수값을 다 잘라서 0으로 강제 변환시키는 것.
            float ndotl = saturate(dot(s.Normal, lightDir)); 
            float3 DiffColor; // 디퓨즈컬러, 즉 램버트(램버트 라이팅은 다른 말로 디퓨즈 라이팅이라고도 함.) 조명 연산이 적용된 컬러값을 따로 변수로 빼놓음.
            DiffColor = ndotl * s.Albedo * _LightColor0.rgb * atten;  // Albedo 텍스쳐 색상값, 빛의 강도 및 색상(_LightColor 내장변수), 감쇄(atten) 을 모두 적용한 램버트(디퓨즈) 컬러

            final.rgb = DiffColor.rgb;
            final.a = s.Alpha;

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
