Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {} // 유니티는 인터페이스로부터 입력받는 변수명을 '_BumpMap' 이라고 지으면, 텍스쳐 인터페이스는 노말맵을 넣을 것이라고 인지함.
        _SpecCol ("Specular Color", Color) = (1, 1, 1, 1) // 스펙큘러의 색상을 인터페이스로 받기 위해 프로퍼티 추가
        _SpecPow ("Specular Power", Range(10, 200)) = 100 // 스펙큘러의 강도(거듭제곱. 높을수록 스펙큘러 영역이 좁아짐)를 인터페이스로 받기 위해 프로퍼티 추가
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        // Test 라는 이름의 커스텀 라이팅 구현
        #pragma surface surf Test // noambient // 환경광 영향 제거

        sampler2D _MainTex;
        sampler2D _BumpMap;
        float4 _SpecCol;
        float _SpecPow;

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
        float4 LightingTest(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten) { // 카메라 벡터가 필요한 경우, 커스텀 라이팅 함수의 인자를 4개 전달하고, 세 번째 인자를 viewDir 로 들어오도록 하면 됨. (순서를 반드시 지켜야 함.)
            float4 final; // 최종 색상값을 담아서 리턴해줄 변수

            // Lambert term (램버트(디퓨즈) 라이팅 계산 영역)
            // surf 에서 Unpack 해준 노말값과 조명벡터를 내적하여 밝기값을 구함.
            // 이때, 내적은 -1 ~ 1 사이의 값을 포함하므로, 음수값이 존재하면 다른 조명값이나 색상 추가해줘도 계속 어두운 색상으로 찍힘.
            // 이를 해결하기 위해 saturate() 내장함수로 0 미만의 음수값을 다 잘라서 0으로 강제 변환시키는 것.
            float ndotl = saturate(dot(s.Normal, lightDir)); 
            float3 DiffColor; // 디퓨즈컬러, 즉 램버트(램버트 라이팅은 다른 말로 디퓨즈 라이팅이라고도 함.) 조명 연산이 적용된 컬러값을 따로 변수로 빼놓음.
            DiffColor = ndotl * s.Albedo * _LightColor0.rgb * atten;  // Albedo 텍스쳐 색상값, 빛의 강도 및 색상(_LightColor 내장변수), 감쇄(atten) 을 모두 적용한 램버트(디퓨즈) 컬러

            // Spec term (blinn-phong 스펙큘러 밝기값 계산 영역)
             // 퐁 반사 모델에서 스펙큘러를 구하는 공식이 간략화된 '블린-퐁 공식'으로 스펙큘러 계산
            float3 SpecColor;
            float3 H = normalize(lightDir + viewDir); // 우선 카메라벡터와 조명벡터의 절반벡터를 구한 뒤, 길이를 1로 맞춤. (p.354 참고)
            float spec = saturate(dot(H, s.Normal)); // 본격적인 스펙큘러 연산. 하프벡터와 노말벡터를 내적함. -> 내적은 -1 ~ 1 사이니까 saturate() 로 음수값은 0으로 초기화함.
            spec = pow(spec, _SpecPow); // 근데 위에 처럼 날것의 spec 값을 그대로 리턴하면, 스펙큘러 영역이 너무 넓어서 죄다 흰색으로 찍힘. -> 그래서 이거를 100거듭제곱 해줘서, 특정 구간부터 확 밝아지도록 한 것. (p.330 참고)
            SpecColor = spec * _SpecCol.rgb; // spec 값은 float 한개니까, 인터페이스로 받아온 스펙큘러 색상값인 _SpecCol.rgb 에 곱해줌으로써, 해당 스펙큘러값 만큼의 밝기값을 갖는 색상을 계산할 수 있음.

            // Final term (최종 색상값 계산 영역)
            final.rgb = DiffColor.rgb + SpecColor.rgb; // 램버트 라이팅 연산과 블린-퐁 스펙큘러 연산을 더해서 최종 색상값을 결정함.
            final.a = s.Alpha;

            // return final;
            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
