Shader "Custom/customLight"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("NormalMap", 2D) = "bump" {} // 유니티는 인터페이스로부터 입력받는 변수명을 '_BumpMap' 이라고 지으면, 텍스쳐 인터페이스는 노말맵을 넣을 것이라고 인지함.
        _SpecCol ("Specular Color", Color) = (1, 1, 1, 1) // 스펙큘러의 색상을 인터페이스로 받기 위해 프로퍼티 추가
        _SpecPow ("Specular Power", Range(10, 200)) = 100 // 스펙큘러의 강도(거듭제곱. 높을수록 스펙큘러 영역이 좁아짐)를 인터페이스로 받기 위해 프로퍼티 추가
        _SpecCol2 ("Specular Color2", Color) = (0.7, 0.7, 0.7, 1) // 가짜 스펙큘러의 색상을 인터페이스로 받기 위해 프로퍼티 추가
        _SpecPow2("Specular Power2", Range(10, 200)) = 50 // 가짜 스펙큘러의 강도(거듭제곱. 높을수록 스펙큘러 영역이 좁아짐)를 인터페이스로 받기 위해 프로퍼티 추가
        _GlossTex ("Gloss Tex", 2D) = "white" {} // 부위별로 스펙큘러 강도를 다르게 조절해주기 위해 필요한 Spec 텍스쳐를 인터페이스로 받기 위해 프로퍼티 추가

        _RimCol("Rim Color", Color) = (0.5, 0.5, 0.5, 1) // 프레넬의 색상을 인터페이스로 받기 위해 프로퍼티 추가
        _RimPow("Rim Power", Range(1, 10)) = 6 // 프레넬의 두께(강도?, 값이 작을수록 넓어짐)를 인터페이스로 받기 위해 프로퍼티 추가
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        // Test 라는 이름의 커스텀 라이팅 구현
        #pragma surface surf Test // noambient // 환경광 영향 제거

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
            float4 m = tex2D(_GlossTex, IN.uv_GlossTex); // 스펙큘러 강도 조절을 위해 받아온 텍스쳐(교재에서는 GlossMap 을 사용하지만, 여기서는 Spec 맵을 사용할거임. 알파값을 grayScale 로 생성하기 적합한 게 이거라서...)
            o.Albedo = c.rgb;

            // UnpackNormal() 함수는 변환된 노말맵 텍스쳐 형식인 DXTnm 에서 샘플링해온 텍셀값 float4를 인자로 받아 float3 를 리턴해줌.
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));

            /*
                스펙큘러 강도 조절을 위해 받아온 Spec 텍스쳐는 jpg 이므로 알파채널을 포함하지 않음. 
                따라서 유니티에서 Alpha Source 를 'From Gray Scale' 로 지정해서 알파채널을 직접 만들어줌. 
                이 직접 만들어준 알파채널을 o.Gloss 구조체 속성값에 넣어준 것.

                o.Gloss 프로퍼티는 모델의 부위별 Specular 의 강도(?) 를 표현한 것으로,
                순수한 Specular 의 opacity 같은 느낌이라고 보면 됨.

                해당 설명은 p.253 에 나와있음.
            */
            o.Gloss = m.a;
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
            // SpecColor = spec * _SpecCol.rgb; // spec 값은 float 한개니까, 인터페이스로 받아온 스펙큘러 색상값인 _SpecCol.rgb 에 곱해줌으로써, 해당 스펙큘러값 만큼의 밝기값을 갖는 색상을 계산할 수 있음.
            SpecColor = spec * _SpecCol.rgb * s.Gloss; // 스펙큘러의 강도, opacity에 해당하는 구조체 s.Gloss 값을 곱해줌으로써, 부위별 스펙큘러 강도를 조절함.

            // Rim term (Rim 라이트, 즉 Fresnel 계산 영역)
            // 원래 surf 함수에서 Input 구조체로부터 가져오던 버텍스 -> 카메라 벡터인 viewDir 을 커스텀라이팅 함수에서도 가져올 수 있게 되었으므로,
            // 가져올 수 있게 된 김에 프레넬도 구연해서 최종 색상값에 더해서 적용해보자는 것.
            float3 rimColor; // 최종 프레넬 연산 결과값을 저장할 변수
            float rim = abs(dot(viewDir, s.Normal)); // 뷰 벡터와 노말맵의 노말벡터를 내적한 뒤, 내적결과값에서 음수를 제거하기 위해 abs() 를 사용함. 
            float invrim = 1 - rim; // rim값 자체는 카메라와 향하는 곳일수록 밝고, 가장자리일수록 어두우므로, 1에서 빼줘서 내적값을 뒤집어줘서, 가장자리로 갈수록 밝은 값이 나오도록 함.
            rimColor = pow(invrim, _RimPow) * _RimCol.rgb; // 프레넬의 두께와 색상을 조절하기 위해 거듭제곱 처리 및 특정 색상(여기서는 회색이지?)과 곱해줌.

            // Fake Spec term (Fresnel 연산의 부산물인 rim 값을 이용한 가짜 스펙큘러 계산 영역)
            float3 SpecColor2; // 가짜 스펙큘러를 계산해서 저장할 변수
            SpecColor2 = pow(rim, _SpecPow2) * _SpecCol2.rgb * s.Gloss; // SpecColor와 마찬가지로 거듭제곱처리, 스펙큘러 색상 적용(여기서는 옅은 회색), s.Gloss 값으로 스펙큘러 강도(opacity) 적용

            // Final term (최종 색상값 계산 영역)
            // final.rgb = DiffColor.rgb + SpecColor.rgb; // 램버트 라이팅 연산과 블린-퐁 스펙큘러 연산을 더해서 최종 색상값을 결정함. -> 퐁 반사 모델에서도 앰비언트 컬러 + 디퓨즈 + 스펙큘러 이런 식으로 각 성분의 값을 더해서 계산했었지? (WebGL 책 참고)
            // final.rgb = DiffColor.rgb + SpecColor.rgb + rimColor.rgb; // 프레넬 연산값도 최종 색상에 더해줌.
            final.rgb = DiffColor.rgb + SpecColor.rgb + rimColor.rgb + SpecColor2.rgb; // 가짜 스펙큘러 값도 최종 색상에 더해줌. (실제 세상에서는 조명이 여러 개 있는 경우가 많으므로, 이런 식으로 rim값을 이용해 가짜 스펙큘러를 추가해주는 게 디테일을 살리기 위해 권장하는 방식이라고 함.)
            final.a = s.Alpha;

            // 값을 뒤집지않은 rim을 200 제곱해서 리턴해주면, 카메라 시선을 따라 하이라이트 영역이 움직이는 걸 볼 수 있음.
            // 즉, '뒤집어지지 않은 rim값 == 스펙큘러' 라고도 할 수 있는 것이지! 
            // Fresnel 연산의 부산물에 불과한 rim값이 사실상 스펙큘러와 유사한 결과를 만들어 내는 것임.
            // 따라서, 얘를 그냥 spec 값 대신 사용해도 무방함!
            // return pow(rim, 200); 

            return final;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
